# Ch.10 Combining Operators in Practice

## A. 시작하기

* **Our Planet**이라는 작은 앱을 만들어 볼 것이다. 이 앱은 NASA에서 배포한 공공 데이터인 EONET; NASA's Earth Observatory Natural Event Tracker를 타겟으로 할 것이다. [자세히 알아보기](https://eonet.sci.gsfc.nasa.gov)
* 이 예제를 통해 구현하려는 것은 다음과 같다.
	* 첫 화면에 [EONET 공공 API](https://eonet.sci.gsfc.nasa.gov/docs/v2.1)에서 받아온 이벤트 카테고리를 보여주기 
	* 이벤트를 다운로드하고 각각의 카테고리 개수를 보여주기
	* 사용자가 카테고리를 탭했을 때 해당 카테고리의 이벤트 리스트를 보여주기

## B. 웹 백엔드 서비스 준비하기

* 좋은 앱은 각각의 책임을 분명히 정의한 아키텍처를 가지고 있다. EONET API와 통신하는 코드는 어떠한 view controller에도 있으면 안된다. 코드가 특별한 상태에 존속되지 않는다면, 해당 코드는 단순한 static 함수와 함께 클래스로 분리할 수 있을 것이다.
* 이 예제에서는 EONET API와 통신하는 부분을 *EONET service* 라고 부를 것이다. EONET이 배포하는 데이터에 접근하고 이를 앱에게 서비스로서 제공한다. 이를 통해 앱 내부에서 데이터의 생성과 소비를 구분할 수 있으며, 이렇게 Rx를 이용한 패턴은 다른 앱에서도 흔하게 볼 수 있을 것이다. 
* **OurPlanet** 앱의 **Model** 폴더를 열어보면 이미 서비스 데이터 structure들이 제공되어 있다. 이 중 API로부터 받은 콘텐츠를 매핑한 `EOCategory`와 `EOEvent` structure들을 미리 살펴보도록 하자. 
* **Model/EONET.swift**를 보면 이미 기본적인 클래스 구조는 구현되어 있다. 
* 모든 EONET 서비스 API들은 비슷한 구조를 가지고 있다. 이제 EONET에서 데이터를 받고 카테고리와 이벤트를 읽을 때 사용할 일반적인 리퀘스트 메커니즘을 구현해보자.

### 1. 일반적인 리퀘스트 요청

* `request(endpoint:query:)`로 코딩하는 것부터 시작할 것이다. 목적은 다음과 같다. 
	* EONET API에 데이터 리퀘스트
	* generic dictionary로 리스폰스 디코딩
	* 발생할 수 있는 모든 에러 감안하기
* 새로운 `request(_:_:)` 함수를 만들자. 

	```swift
	// 1
	static func request(endpoint:String, query: [String: Any] = [:]) -> Observable<[String: Any]> {
	    do {
	        guard let url = URL(string: API)?.appendingPathComponent(endpoint),
	        var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { throw EOError.invalidURL(endpoint) }
	     
	        // 2
	        components.queryItems = try query.flatMap { (key, value) in
	            guard let v = value as? CustomStringConvertible else { throw EOError.invalidParameter(key, value) }
	            return URLQueryItem(name: key, value: v.description)
	        }
	        guard let finalURL = components.url else { throw EOError.invalidURL(endpoint) }
	        
	        // 3
	        let request = URLRequest(url: finalURL)
	        
	        return URLSession.shared.rx.response(request: request)
	            .map { _, data -> [String: Any] in
	                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
	                    let result = jsonObject as? [String: Any] else { throw EOError.invalidJSON(finalURL.absoluteString)}
	                return result
	        }
	        // 4
	    } catch {
	        return Observable.empty()
	    }
	}
	```
	
	* 1) 파라미터는 endpoint, query 두 가지다. 만약 URL이 구성되지 못하면 (예. 서비스 URL이 변경되거나 오타가 났을 경우 같은) 에러를 발생시킬 것이다. 
	* 2) 여기서 사용한 `.rx` (RxCocoa) 에 대한 것은 [Ch.12](https://github.com/fimuxd/RxSwift/blob/master/Lectures/12_Beginning%20RxCocoa/Ch12.%20Beginning%20RxCocoa.md), [13](https://github.com/fimuxd/RxSwift/blob/master/Lectures/13_Intermediate%20RxCocoa/Ch13.Intermediate%20RxCocoa.md)에서 다룰 것이다. 
	* 3) 이러한 구조는 이제 익숙하다고 느껴야 한다. `URLSession`의 `rx.response`는 리퀘스트 결과를 통해 observable을 생성한다. 데이터를 받으면 이를 객체로 deserialize 할 것이다. 캐스팅 타입은 `[String: Any]` dictionary가 될 것이다.
	* 4) `try-do-catch` 구문을 완성한다. 에러 처리에 대한 자세한 내용은 [Ch.14](https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/Ch.14%20Error%20Handling%20in%20Practice.md)에서 다룰 것이다. 

### 2. 카테고리 패치하기

* EONET에서 카테고리를 가져오기 위해 `categories` API endpoint를 때릴 것이다. 이 카테고리는 거의 변경되지 않기 때문에 Singleton으로 만들 수도 있다. 하지만 비동기적으로 패치할 것이므로, 이들을 꺼내오는 가장 좋은 방법은 `Observable<[EOCategory]>`로 가져오는 것이다. 다음 코드를 EONET 클래스에 추가하자.

	```swift
	static var categories: Observable<[EOCategory]> = {
	    return EONET.request(endpoint: categoriesEndpoint)
	        .map { data in
	            let categories = data["categories"] as? [[String: Any]] ?? []
	            return categories
	                .flatMap(EOCategory.init)
	                .sorted { $0.name < $1.name }
	        }
	        .catchErrorJustReturn([])
	        .share(replay: 1, scope: .forever)
	}()
	```
	
	* 이전 ch.에서 배운 내용들을 적용해볼 수 있다.
		* `categories` endpoint에서 데이터 리퀘스트 하기
		* 리스폰스에서 `categories` array 추출하기
		* 추출한 놈들을 `EOCategory` array 객체로 매핑하고 이들을 이름별로 정렬하기
		* 만약 네트워크 에러가 발생하면 빈 array를 내보낸다. 
	* 마지막의 `.share(replay:,scope:)`를 사용한 목적이 무엇인지 궁금할 것이다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/10_Combining%20Operators%20in%20Practice/1.share.png?raw=true" height = 300>

		* `categories` observable은 singleton(`static var`) 이다. 따라서 모든 구독은 같은 놈을 받게 될 것이다. 따라서, 
		* 첫 번째 구독자는 `request` observable에 대한 구독을 시작한다.
		* `share(reply: 1, scope: .forever)` 는 모든 요소들을 첫 번째 구독자에게 공급한다.
		* 그리고 마지막으로 받은 요소를 데이터 재요청 없이 새로운 구독자에게 *리플레이* 한다. 캐시처럼 작동하는 것이다. 이 것이 `.forever` scope의 목적이다. 
* 이제 이들을 categories view controller에 묶을 준비가 되었다.  

## C. Categories view controller

* **CategoriesViewController.swift**를 열어보자. 여기에 `UITableViewController`를 띄울 것이다. 따라서 표시를 위해 로컬에 저장된 카테고리가 필요할 것이다. 빈 array를 초기값을로 갖는 `Variable`을 추가하는 것 부터 시작하자. 이 놈을 구독함으로써 새로운 데이터가 도착할 때마다 table view를 업데이트하게 될 것이다. 
* `Variable`과 `DisposeBag`을 추가하자. 

	```swift
	let categories = Variable<[EOCategory]>([])
	let disposeBag = DisposeBag()
	```

* table view 아이템 개수를 얻기 위해 `categories` variable에서 현재 콘텐츠들을 당겨오자. 다음 코드를 `tableView(_:numberOfRowsInSection):`에 추가하자.

	```swift
	return categories.value.count
	```
	
	* 여기서는 `categories` variable로 부터 바로 현재 값을 읽고 있다. 나중에 RxCocoa를 이용한 보다 나은 방법을 배울 것이다. 지금은 일단 간단하게 넘어가자.
* 카테고리 표시를 위해 간단한 default cell을 사용한다. 다음 코드를 `tableView(_:cellForRowAt:)`에 추가한다. 

	```swift
	let category = categories.value[indexPath.row]
	cell.textLabel?.text = category.name
	cell.detailTextLabel?.text = category.description
	``` 
	
* 이로써 기본 셋팅은 끝났다. 만약 이 상태로 앱을 구동하면 아무런 카테고리도 뜨지 않는다. 카테고리를 띄우기 위해서는 EONET 서비스의 observable을 구독하는 것이다. `startDownload()` 함수 내에 다음 코드를 입력하자.
	
	```swift
	let eoCategories = EONET.categories
	    
	eoCategories
	    .bind(to: categories)
	    .disposed(by: disposeBag)
	``` 

	* EONET 서비스가 실질적인 작업을 다해주기 때문에 여기서 특별히 추가해야할 기능은 없다.
	* `bind(to:)`는 관찰자(`categories` variable)와 소스 observable(`EONet.categories`)을 연결한다. 
* 이제 테이블 뷰 업데이트를 위한 `Variable` 구독은 끝났다. 다음 코드를 `viewDidLoad()`상 `startDownload`이전에 추가하자.


	```swift
	categories
	    .asObservable()
	    .subscribe(onNext: { [weak self] _ in
	        DispatchQueue.main.async {
	            self?.tableView.reloadData()
	        }
	    })
	    .disposed(by: disposeBag)
	```
	
	* 여기서 `DispatchQueue`를 사용한 것은, 테이블뷰 업데이트를 메인 쓰레드에서 이루어지도록 하기 위함이다. 
	* 추후 ch.15에서 스케줄러와 `observeOn(_:)` 연산자의 사용에 대해 배우게 될 것이다. 

## D. 이벤트 다운로드 서비스 추가하기

* EONET API는 이벤트 다운로드를 할 수 있는 두 개의 endpoint(all events, events per category)를 제공한다. 각각은 *open* 및 *closed* 이벤트에 대한 차이점도 있다.
* *Open* 이벤트는 진행중인 놈들이다. *Closed* 이벤트는 종료되어 과거에 있는 녀석들이다. 실제 EONET 리퀘스트 파라미터 중 우리가 관심있을 놈들은 다음과 같다.
	* 이벤트 검색을 위해 되돌아볼 *일수*
	* 이벤트의 *open* 또는 *closed* 상태
* API는 *open* 또는 *closed* 이벤트를 별도로 다운로드 하도록 권고하고 있다. 하지만 여전히 우리는 이들을 하나의 흐름을 통해 구독하고 싶어한다. 일단 생각해볼 수 있는 방법은 리퀘스트를 두 번 보낸 뒤 각각의 결과를 연결하는 것이다. 
* 다음 함수를 `EONET.swift`에 추가하자. 

	```swift
	fileprivate static func events(forLast days: Int, closed: Bool) -> Observable<[EOEvent]> {
	    return request(endpoint: eventsEndpoint, query: ["days": NSNumber(value: days),
	                                                     "status": (closed ? "closed" : "open")])
	        .map { json in
	            guard let raw = json["events"] as? [[String: Any]] else { throw EOError.invalidJSON(eventsEndpoint)}
	            return raw.flatMap(EOEvent.init)
	        }
	        .catchErrorJustReturn([])
	}
	```
	
	* 이제 JSON을 처리하는 익숙한 모습이 나왔다. `request(_:_:)` 함수는 이미 JSON을 디코딩 했다. 따라서 우리가 할 일은 이벤트 array들을 `EOEvent` 객체 array로 매핑하는 것 뿐이다.
	* 주의할 점! 여기서는 RxSwift의 `map(_:)`을 이용하여 `[String: Any]` observable을 `[EOEvent]` observable로 만들었다. 하지만 클로저에서는 *Swift*의 `flatMap(_:)`을 이용해서 dictionary를 이벤트 array로 전환한다. (Rx 코드에 익숙해지기 전까지는 이 둘의 미묘한 차이 때문에 한동안 혼란스러울 수 있다.) 
* 이제 EONET 서비스에 새로운 함수를 추가하여 `[EOEvnet]` observable을 제공할 수 있도록 하자.

	```swift
	static func events(forLast days: Int = 360) -> Observable<[EOEvent]> {
	    let openEvents = events(forLast: days, closed: false)
	    let closedEvents = events(forLast: days, closed: true)
	    
	    return openEvents.concat(closedEvents)
	}
	```
	
	* 이 함수는 이벤트 호출을 위해 view controller에서 호출하게 될 것이다. `concat(_:)` 연산자를 사용한 것을 눈치챘는지? 이 녀석은 다음과 같이 작동한다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/10_Combining%20Operators%20in%20Practice/2.%20concat.png?raw=true" height = 200>

* 이제 이벤트 다운로드 기능을 categories view controller에 추가할 준비가 되었다. 

## E. 카테고리의 이벤트 얻기

* `CategoriesViewController.swift`로 돌아가보자. `startDownload()` 의 카테고리 메커니즘에 이벤트 다운로드에 대한 내용을 추가할 필요가 있다. 아마 각각의 카테고리에 대해 이벤트를 채우고 싶겠지만, 그렇게 하면 다운로드 시간이 오래 걸린다. 가능한한 최고의 UX를 제공하기 위해 다음과 같은 작업을 할 것이다. 

	* 카테고리를 다운로드 하고 이들을 먼저 화면에 띄운다.
	* 지난 1년간의 모든 이벤트를 다운로드 한다.
	* 각각의 카테고리에 대한 이벤트 수를 카테고리 목록에 업데이트 한다.
	* disclosure indicator를 추가한다.
	* 카테고리를 선택했을 때 event list view controller로 푸시한다.

### 1. 이벤트와 함께 카테고리 업데이트 하기

* 먼저 `startDownload()`에 다음과 같이 추가한다.

	```swift
	let eoCategories = EONET.categories
	let downloadedEvents = EONET.events(forLast: 360)
	```
	
	* 2개의 observable 로 부터 시작한다. `eoCategories`는 모든 카테고리 array를 다운로드 한다. `downloadedEvents`는 EONET 클래스에 추가한 `events` 함수를 호출하여 지난 1년간의 이벤트들을 다운로드 한다.
* 이제 테이블 뷰에 필요한 것은 카테고리 리스트다. `EOCategory` 모델로 들어가면 `events` 프로퍼티를 찾을 수 있다. 이 녀석은 `var` 이므로 각 카테고리별로 다운로드한 이벤트를 추가할 수 있다. 다음 코드를 `startDownload()`에 추가하자.

	```swift
	let updatedCategories = Observable
	    .combineLatest(eoCategories, downloadedEvents) { (categories, events) -> [EOCategory] in
	        return categories.map { category in
	            var cat = category
	            cat.events = events.filter { $0.categories.contains(category.id) }
	            return cat
	        }
	}
	```
	
	* `combineLatest(_:_:resultSelector:)`를 이용해서 downloaded categories와 downloaded events를 병합하고 이벤트를 가지는 업데이트된 카테고리 리스트를 만들어낸다. 여기서의 동작은 다음과 같이 나타낼 수 있다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/10_Combining%20Operators%20in%20Practice/3.%20combine.png?raw=true" height = 280>
	
	* `updatedCategories` observable은 `Observable<[EOCategory]>` 타입이 될 것이다. 왜냐하면 클로저의 반환타입이 `[EOCategory]` 이기 때문이다. 이 것은 `map` 연산자를 통해 새로운 observable 타입을 생성하게 해준다. 
	* 나머지 코드들은 일반적인 Swift 코드이다. 
* 마지막으로, `categories` variable을 다음과 같이 바인딩 하자.

	```swift
	eoCategories
	    .concat(updatedCategories)
	    .bind(to: categories)
	    .disposed(by: disposeBag)
	```
	
	* 여기서 `concat(_:)`을 사용하여 `eoCategories` observable과 `updatedCategories` observable에서 나온 아이템들을 바인딩하였다.
		
### 2. 디스플레이 업데이트 하기

* 이벤트 수를 표시하고 인디케이터를 표시하기 위해 `tableView(_:cellForRowAt:)` 업데이트를 해야한다.
* cell의 `textLabel` 설정을 변경하고 인디케이터를 추가한다. 

	```swift
	cell.textLabel?.text = "\(category.name) (\(category.events.count)"
	cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator : .none
	```
	
* 앱을 구동해보면 제대로 작동하는 것을 알 수 있다. 하지만 카테고리가 나타나고 이벤트로 채워지기 전에 상당 시간 지연되는 것을 알 수 있다. 이건 EONET API가 업데이트 하는데 시간이 필요하기 때문이다. 아무튼 우리는 지난 한 해의 데이터를 리퀘스트 해야한다! 이걸 개선하려면 뭘 할 수 있을까?

### 3. 병렬적으로 다운로드 하기

* EONET API가 open과 closed 이벤트를 별도로 전달한다는 점을 기억하자. 지금까지는 `concat(_:)`을 사용했다. RxSwift의 좋은 점은 이들을 어떤 UI 코드에 영향없이 바꿀 수 있다는 점이다. EONET 서비스 클래스는 `[EOEvent]` observable을 배출하고, 이 녀석은 리퀘스트 개수에 영향을 받지 않는다. 
* `EONET.swift` 파일을 열어서 `events(forLast:)`로 이동하자. 그리고 `event(forLast:)`의 `return` 문을 다음의 코드로 대체하자.

	```swift
	return Observable.of(openEvents, closedEvents)
		.merge()
		.reduce([]) { running, new in 
			running + new
		}
	```
	
	* 먼저, observable을 가지는 observable을 만들었다.
	* `merge()` 연산자를 이용해서 이 둘을 합친다. 이들은 소스 observable에 의해 방출된 각 observable들과 방출된 요소들을 구독한다. 
	* array 형태의 결과물을 만든다. 빈 array로 시작하여 매번 observable이 이벤트 array를 전달하고, 클로저는 호출된다. 기존의 array에 새로운 array를 더한 다음 반환한다. 이는 observable이 complete 될 때까지 진행 상태를 유지하게 된다. 한번 complete 되면, `reduce`는 하나의 값(현재 상태)를 방출한 뒤 complete 된다. 

 		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/10_Combining%20Operators%20in%20Practice/4.%20merge.png?raw=true" height = 100>
 		
* 앱을 구동해보자. 아마 미세하게 다운로드 시간이 개선된 것을 확인할 수 있을 것이다. 
* UI code를 건드리지 않고도 EONET 서비스 과정을 변경할 수 있다는 점은 아주 매력적이다. 이것이 Rx 코드의 큰 장점 중 하나다. producer와 consumer를 깔끔하게 분리함으로써 많은 유동성을 제공해주는 것이다.

## F. Events view controller

* `EvnetsViewController.swift`를 열고 다음의 프로퍼티들을 추가하자.

	```swift
	let events = Variable<[EOEvent]>([])
	let disposeBag = DisposeBag()
	```

* `events`가 새로운 값을 받을 때마다 테이블 뷰가 업데이트 될 수 있도록 `viewDidLoad()`에 다음 코드를 추가하자.

	```swift
	events.asObservable()
		.subscribe(onNext: { [weak self] _ in 
			self?.tableView.reloadData()
		})
		.disposed(by: disposeBag)
	```

	* 이벤트가 background 큐에서 방출될 수 있기 때문에 업데이트가 메인 큐에서 발생하는지 확인하는 것이 좋다. 

* 이제 `tableView(_:numberOfRowsInSection:):` 부분을 다음과 같이 변경한다.

	```swift
	return events.value.count
	```

* `tableView(_:cellForRowAt:)`에 다음과 같이 셀을 configure한다.

	```swift
	let event = events.value[indexPath.row]
	cell.configure(event: event)
	```

* view controller에 이벤트를 푸쉬하는 역할을 할 다음 코드를 `CategoriesViewController`에 추가한다.

	```swift
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let category = categories.value[indexPath.row]
		if !category.events.isEmpty {
			let eventsController = storyboard!.instantiateViewController(withIdentifier: "events") as! EventsViewController
			eventsController.title = category.name
			eventsController.events.value = category.events
			
			navigationController!.pushViewController(eventsController, animated: true)
		}
		tableView.deselectRow(at: indexPath, animated: true)
	}
	```
	
	* Event view controller의 `Variable<[EOEvent]>` 은 이벤트들을 가진다. 이 variable의 값은 자동적으로 테이블뷰의 업데이트를 시작시킨다. view의 로딩 여부는 중요하지 않다. observable아 고마워!
	
## G. days selector 연결하기

* 연결*wire*에 대한 일반적인 접근법은 다음과 같다.
	* 현재 슬라이더 값을 Variable<Int> 에 바인딩 한다.
	* 슬라이더 값을 가지는 이벤트만 필터한 이벤트 리스트로 결합한다.
	* 테이블뷰를 필터된 이벤트들로 바인드 한다.
* `days`와 `filteredEvents` 라는 variable들을 `EventsViewController`에 추가한다.

	```swift
	let days = Variable<Int>(360)
	let filteredEvents = Variable<[EOEvent]>([])
	```
	
	* 이벤트를 필터하려면 최근 `days` 값에 `events`를 더한 뒤 필터해야한다. 우리는 최근 N일 동안의 데이터에만 관심이 있다. 
* 다음의 코드를 `viewDidLoad()`에 추가하자.

	```swift
	Observable.combineLatest(days.asObservable(), events.asObservable()) { (days, events) -> [EOEvent] in
	    let maxInterval = TimeInterval(days * 24 * 3600)
	    return events.filter { event in
	        if let date = event.closeDate {
	            return abs(date.timeIntervalSinceNow) < maxInterval
	        }
	        return true
	    }
	}
	.bind(to: filteredEvents)
	.disposed(by: disposeBag)
	``` 
	
	* 여기서는 `combineLastest`를 사용하였다. `days`와 `events` variable을 결합한 것이다. 여기서의 클로저는 에빈트를 필터하고 필요하다고 설정한 일수 만큼의 이벤트만을 필터링한다. 
	* 이렇게 작성한 observable을 `filteredEvnets` variable에 바인딩할 수 있다. 
* 이제 두 개의 바인딩 작업을 해야 한다.
	* `filterEvents`를 테이블 뷰에 바인딩 
		* 테이블뷰를 업데이트 하기 위해 `viewDidLoad()`내에 `events`를 `filteredEvents`로 바꾸자	
			```swift
			filteredEvents.asObservable()
				.subscribe(onNext: { [weak self] _ in 
					self?.tableView.reloadData()
				})
				.disposed(by: disposeBag)
			```
			
	* `days`값을 슬라이더에 바인딩
		* `sliderAction(_:)` 함수 - 스토리보드의 days slider는 이미 action 메소드로 연결되어있다. 사용자가 언제든지 슬라이더를 이동하여 `days`를 업데이트 할 수 있도록 다음 코드를 추가하자.
		
			```swift
			days.value = Int(slider.value)
			```
			
		* 이제 `tableView(_:numberOfRowsInSection:)`의 반환값을 다음과 같이 수정하자.

			```swift
			return filteredEvents.value.count
			```
		
		* 변경 값을 다른 data source 메소드에도 반영할 필요가 있다. `tableView(_:cellForRowAt:)` 의 `event` 부분을 다음으로 변경하자.

			```swift
			let event = filteredEvents.value[indexPath.row]
			```
		
		* `viewDidLoad()`로 가서 다음 코드를 추가하자.

			```swift
			days.asObservable()
			    .subscribe(onNext: { [weak self] days in
			        self?.daysLabel.text = "Last \(days) days"
			    })
			    .disposed(by: disposeBag)
			```

## H. 이벤트 다운로드 쪼개보기

* 카테고리별로 다운로드를 쪼개보는 작업을 할 것이다. EONET API를 통해 모든 이벤트를 한번에 다운로드 받을 수도 있지만, 카테고리별로 다운로드 하는 것도 가능하다.
* 여기서 진행할 작업은 다음과 같다.
	* 먼저 카테고리를 받는다.
	* 각각의 카테고리에 대해서 이벤트를 리퀘스트한다.
	* 새로운 이벤트 블록이 올 때마다 카테고리를 업데이트 하고 테이블뷰를 새로고침한다.
	* 모든 카테고리가 이벤트값을 가질 때까지 계속한다. 

### 1. EONET에 카테고리별 이벤트 다운로드 추가하기

* 카테고리별로 이벤트를 다운로드하기 위해서 접근할 API내 정확한 endpoint를 확인해야 한다. **EONET.swift**의 `events(forLast:closed:)`내의 endpoint 부분을 다음과 같이 수정하자.
	
	```	swift
	fileprivate static func events(forLast days: Int, closed: Bool, endpoint: String) -> Observable<[EOEvent]> {
	    return request(endpoint: endpoint, query: ["days": NSNumber(value: days),
	                                                     "status": (closed ? "closed" : "open")])
	        .map { json in
	            guard let raw = json["events"] as? [[String: Any]] else { throw EOError.invalidJSON(endpoint)}
	            return raw.flatMap(EOEvent.init)
	        }
	        .catchErrorJustReturn([])
	}
	```
	
* `events(forLast:)` 메소드로 가서 다음과 같이 수정하자.

	```swift
	static func events(forLast days: Int = 360, category: EOCategory) -> Observable<[EOEvent]> {
	    let openEvents = events(forLast: days, closed: false, endpoint: category.endpoint)
	    let closedEvents = events(forLast: days, closed: true, endpoint: category.endpoint)
	    
	    return Observable.of(openEvents, closedEvents)
	        .merge()
	        .reduce([]) { running, new in
	            running + new
	    }
	}
	```
	
* 이로써 서비스 부분을 업데이트 하는 것은 끝났다.

### 2. 서서히 UI 업데이트하기

* `CategoriesViewController`로 이동하여 Rx 액션을 추가할 차례다.
* 다운로드한 각각의 카테고리의 이벤트들은 `flatMap`을 통해 하나의 observable로 나열될 수 있다. 
* `CategoriesViewControoler.swift`내에 `startDownload()`를 확인하면 parameter가 없다며 컴파일러가 에러를 표시하고 있는 것을 확인할 수 있을 것이다. 해당 부분의 코드를 다음으로 수정해주자.

	```swift
	let downloadedEvents = eoCategories.flatMap { categories in
	    return Observable.from(categories.map { category in
	        EONET.events(forLast: 360, category: category)
	    })
	    }
	    .merge()
	```
	
	* 먼저 모든 카테고리를 받을 것이다.
	* 그런 다음 `flatMap`을 호출하여 받은 카테고리들을 각각의 카테고리에 대해 하나의 이벤트 observable을 방출하는 observable로 변환한다.
	* 그리고 이 모든 observable들을 하나의 이벤트 array로 병합한다.
* 지금까지 변경한 내용을 반영하기 위해 `updatedCategories`의 코드도 수정해야 한다. `startDownload()` 내의 `updateCategories` 부분을 다음과 같이 변경하자.

	```swift
	let updatedCategories = eoCategories.flatMap { categories in
	    downloadedEvents.scan(categories) { updated, events in
	        return updated.map { category in
	            let eventsForCategory = EONET.filteredEvents(events: events, forCategory: category)
	            if !eventsForCategory.isEmpty {
	                var cat = category
	                cat.events = cat.events + eventsForCategory
	                return cat
	            }
	            return category
	        }
	    }
	}
	```
	
	* `scan(:accumulator:)` 연산자는 소스 observable이 방출하는 모든 값을 축적한 값을 방출한다. 여기서의 축적값은 카테고리의 업데이트 목록이다.
	* 따라서 새로운 이벤트 그룹이 도달할 때마다, `scan`은 카테고리 업데이트를 방출한다. `updateCategories` observable이 `categories` variable을 기반하는 한, 테이블뷰는 업데이트 될 것이다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/10_Combining%20Operators%20in%20Practice/5.%20flatMapMerge.png?raw=true" height = 180>
		
### 3. 하나만 더

* 만약 우리가 25개의 카테고리를 가지고 있고, 각각에 대해 API 리퀘스트를 두번만 한다고 해도 50개의 리퀘스트를 EONET 서버에 하게 될 것이다. 따라서 API의 최대접속제한값에 닿지 않으려면 동시 송신 요청 수를 제한할 필요가 있다.
* `downloadedEvents` variable의 `merge()` 부분을 다음과 같이 변경하자.
	
	```swift
	.merge(maxConcurrent: 2)
	``` 
	
	* 이 간단한 변화로 observable의 수와 관계없이 동시에 2개까지만 구독하게 된다. 각 이벤트 다운로드는 두개의 리퀘스트를 하므로 한번에 네 가지 리퀘스트만 실행된다. 다른 슬롯은, 슬롯이 확보될 때까지 보류 상태가 된다. 

## I. Challenges

### 1. Challenge 1

* 네비게이션 바에 activity indicator를 두고 이벤트를 패칭하기 시작할 때 돌아가도록 한다. 네트워크로부터 모든 데이터가 패치되면 사라지게 된다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/10_Combining%20Operators%20in%20Practice/6.%20challenge1.png?raw=true" height = 50 >

### 2. Challenge 2

* 이젠 indicator 대신에 다운로드 progress indicator를 추가해보자. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/10_Combining%20Operators%20in%20Practice/7.%20challenge2.png?raw=true" height = 50 >

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
