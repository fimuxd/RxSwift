# Ch.8 Transforming Operators in Practice

## A. 시작하기

* RxSwift repository의 최근 활동이 궁금할 때 어떻게 확인할 수 있을까? 여기서는 GitHub repository의 활동을 보여주는 예제를 작성할 것이다.
* GitHub의 JSON API와 연결하여 가장 최근 패치된 활동을 보여주는 앱을 만들 것이다. 만약 RxSwift repository가 아닌 다른 repository 확인을 원한다면 그렇게 해도좋다.
* 이 프로젝트는 다음과 같은 두 가지 경우에 대한 표현을 할 것이다.
	* GitHub JSON API에 연결해서 JSON 응답을 받는다. 받은 응담을 객체 collection으로 변환한다.
	* 서버에서 새로운 활동 이벤트를 부르기 전까지는 테이블뷰가 기존에 패치되어 디스크에 저장된 내용을 표시하도록 한다.

## B. 웹에서 데이터 패치하기

* 지난 예제를 통해서 웹 URL과 파라미터를 포함하는 `URLRequest`를 생성한 다음, 이를 인터넷으로 보내고 서버의 응답을 받는 작업을 해봤다.
* RxSwift와 기본 RxCocoa의 `URLSession` extension을 사용하여 GitHub API의 JSON을 빠르게 패치할 수 있다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/1.%20RxExtension.png?raw=true" height = 250>

### 1. 리퀘스트 작성을 위해 map 사용하기

* 	GitHub 서버에 보낼 `URLRequest`를 빌드해보자. **ActivityController.swift**를 열고 `viewDidLoad()`를 확인한다. 해당 작업들이 끝났을 때 `refresh()`를 호출하게 될 것이다. `refresh()`가 차례로 `fetchEvents(repo:)`를 호출하고 설정한 repository(예제에서는 "`Reactive/RxSwift`")로 인계한다.
*  `fetchEvents(repo:)` 내부에 다음과 같이 입력한다.

	```swift
	let response = Observable.from([repo])
	```

* 웹 리퀘스트는 repository의 full name으로 시작한다. `URLRequest`를 직접 생성하는 대신 String으로 시작하는 방법은 observable의 입력값으로 유연하게 사용될 수 있다. 즉, repository를 변경하더라도 큰 문제가 되지 않는다는 뜻이다. 이에 대한 자세한 내용은 Challenge 에서 다룰 것이다.
* 주소 string을 가져와서 활성 API 단의 `URL`을 생성한다.

	```swift
	.map { urlString -> URL in
	        return URL(string: "https://api.github.com/repos/\(urlString)/events")!
	```

	* 클로저 축약을 통해 코드를 간단히 할 수 있지만, 여러가지 연산자들을 연달아 쓸 때, 특히 `map`이나 `flatmap`을 함께 사용하는 코드에서는 축약보다 parameter 또는 반환값 타입을 명시하는게 좋을 수 있다. 불일치하거나 누락된 유형에 대한 오류가 표시되면 클로저에 타입정보를 추가할 수 있으니 크게 유의할 부분은 아니다.
* 여기까지 작성해서 `URL`을 얻었으니, 이제 이를 완전한 리퀘스트 형태로 변형하자. 다음의 코드를 마지막 연산자에 추가하자.

	```swift
	.map { url -> URLRequest in
	    return URLRequest(url: url)
	}
	```

	* 이로써 `map`을 이용해 제공된 웹주소를 통해 `URL`을 `URLRequest`로 변형했다. 다음과 같은 과정을 진행한 것이다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/2.%20url%20to%20urlrequest.png?raw=true" height = 65>

### 2. 웹에서의 리스폰스에 대기하기 위해 flatMap 사용하기

* 여러 개의 변형을 연결하면 연결된 각각의 작업들은 동기적으로 일어난다. 즉, 변형연산자*transformation operators* 는 각각의 output에 대해 다음과 같이 진행하게 된다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/3.%20map.png?raw=true" height = 80>

* 여기에 `flatMap`을 삽입하면 다른 효과를 낼 수 있다.
	* 문자열 또는 숫자 array들의 `observable` 같이 일시적으로 요소를 방출하고 완료된 observable들을 flatten 할 수 있다.
	* 비동기적으로 작동하는 observable을 통해 효과적으로 observable들이 "대기"하도록 할 수 있고, 그 동안 다른 연결들은 계속 작동하도록 할 수 있다.
* 다시 말하면 **GitFeed** 프로젝트에서 필요한 작업은 다음 모습과 같다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/4.%20use%20flatmap.png?raw=true" height = 150>

* 따라서 다음 코드를 추가해주자.

	```swift
	.flatMap { request -> Observable<(response: HTTPURLResponse, data: Data)> in
	    return URLSession.shared.rx.response(request: request)
	}
	```

	* RxCocoa의 `URLSession` 객체 내의 `response(request:)` 메소드를 이용했다. 이 메소드는 앱이 웹 서버를 통해 full response를 받을 때마다 complete되는 `Observable<(response: HTTPURLResponse, data: Data)>`를 반환한다.
		* **참고**: 인터넷 연결이 없거나, url이 유효하지 않을 때 `response(request:)`는 에러를 낼 수 있다. 이런 에러들에 대해 관리가 필요한데 자세한 내용은 Ch.14에서 다루고 있다. ([Ch.14 확인하기](https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/Ch.14%20Error%20Handling%20in%20Practice.md))
	* 상기 코드에서 `flatMap`은 웹 리퀘스트를 보내게 해주고 프로토콜이나 델리게이트 *없이도* 리스폰스를 받을 수 있게 해준다. 간단하게 `map`과 `flatMap` 연산자의 조합을 통해 비동기적인 일련의 코드 작성이 가능한 것이다.
* 마지막으로 웹 리퀘스트 결과에 대한 더 많은 구독을 허용하기 위해 `share(replay:, scope:)` 연산자를 추가하자.

	```swift
	.share(replay: 1, scope: .whileConnected)
	```

### 3. share vs. shareReplay

* `URLSession.rx.response(request:)`는 서버로 리퀘스트를 보내고 리스폰스를 받으면 받은 데이터를 `.next` 이벤트를 통해 *단 한번만* 방출한 뒤, complete 된다.
* 만약 observable complete 후 이를 다시 구독하는 상황이 발생하면, 이는 새로운 구독을 생성하고 서버에 별도의 리퀘스트를 또 보내게 될 것이다. 이 같은 상황을 방지하기 위해 `share(replay:, scope:)`을 사용할 수 있다. 이 연산자는 마지막 `replay`로 방출된 요소를 버퍼로 가지고 있다가 새로운 구독자가 생길 때 이를 제공해준다. 그러므로 요청이 completed되고 새로운 관찰자가 `share(replay:, scope:)`을 통해 shared sequence를 구독한다면, 서버를 통해 이미 가지고 있던 버퍼를 즉시 리스폰스로 받을 수 있다.
* `scope`에는 두가지 옵션이 있는데 `.whileConnected`와 `.forever`가 있다.
	* `.whileConnected`: 네트워크 리스폰스 버퍼를 아무도 구독하지 않을 때까지만 가지고 있는 것이다. 구독자가 사라지면 버퍼도 사라진다. 이후 새로운 구독자는 새 네트워크 리스폰스를 가질 것이다.
	* `.forever`: 네트워크 리스폰스 버퍼를 계속 가지고 있는 것이다. 새로운 구독자는 버퍼 리스폰스를 가진다.
* `share(replay:. scope:)`은 complete 할 것으로 예상되는 sequence에 사용해야한다. 이렇게 해야 observable이 다시 생성되는 것을 방지할 수 있다.

## C. 리스폰스 변형하기

* 지금까지는 웹 리퀘스트를 보내기 **이전에** `map`을 사용하여 변형을 했다. 지금부터는 리스폰스를 받은 **이후에** 할 작업에 대해 알아볼 것이다.
* `URLSession` 클래스가 `Data` 객체를 줬는데 바로 작업할 수 있는 형태가 아니라면 어떨까? 당연히 이 것을 JSON으로 변환하여 코드로 *안전하게* 사용할 수 있도록 해야할 것이다.
* `response` observable에 대한 구독을 만들어서 리스폰스 데이터를 객체로 변환할 수 있도록 하자. 하단의 코드를 추가하면 된다.

	```swift
	response
	    .filter { response, _ in
	        return 200 ..< 300 ~= response.statusCode
	}
	```

	* `filter` 연산자를 이용해서 status 코드가 `200`에서 `300` 사이(성공)일 때 받은 리스폰스만 받도록 한다.
		* **참고**: [HTTP 리스폰스 코드 리스트 확인하기](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes)
* 받은 데이터는 이벤트 객체 목록을 포함한 JSON 인코딩된 서버 리스폰스일 것이다. 이렇게 받은 리스폰스 데이터를 `Array<Dictionary<Key:Value>>` 타입으로 변환하자.

	```swift
	.map { _, data -> [[String:Any]] in
	    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
	        let result = jsonObject as? [[String:Any]] else { return [] }
	    return result
	}
	```

	* 리스폰스 객체는 제외하고, 리스폰스 데이터만 받는다.
	* `JSONSerialization`을 통해서 리스폰스 데이터를 디코드하고 결과를 반환한다.
	* `JSONSerialization`이 실패하면 빈 array를 반환한다.
* 다음과 같은 필터를 추가해서 어떤 이벤트 객체도 포함하지 않는 리스폰스를 걸러내자.

	```swift
	.filter { object in
	    return object.count > 0
	}
	```

* 이로써 JSON 객체를 `Event` 객체 조합으로 변환했다. **Event.swift**를 열어보면 아래와 같은 내용들이 이미 구현되어있는 것을 알 수 있다.
	* JSON 객체를 파라미터로 받는 `init`
	* 이벤트를 JSON 객체로 내보내는 `dictionary`라는 이름의 	`dynamic property`
* **ActivityController.swift**로 돌아가서 `fetchEvents(repo:):` 연산자 다음에 다음 내용을 추가하자.

	```swift
	.map { objects in
	    return objects.map(Event.init)
	}
	```

	* 이 `map` 변환은 `[[String: Any]]` 파라미터를 받아서 `[Event]` 결과를 낸다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/5.%20mapEvent.png?raw=true" height = 130>

	* 이 두가지 map의 차이점을 이해해야 한다. 하나는 `Observable<Array<[String: Any]>>`인스턴스에 대한 메소드로 방출하는 각각의 요소에 대해 비동기적으로 작동한다. 두번째 `map`은 `Array`에 대한 메소드로 동기적으로 array내의 요소들을 `Event.init`으로 변환한다.
* 이제 이들을 UI에 업데이트 할 차례다. 코드의 간소화를 위해 UI 코드를 별도의 메소드 `processEvents(_:)`로 만들 것이다. 다음을 마지막 연산자로 추가하자.

	```swift
	.subscribe(onNext: { [weak self] newEvents in
	    self.processEvents(newEvents)
	})
	.disposed(by: bag)
	```

### 1. Processing the response

* 부수작용을 만들 차례다. `ActivityController` 내부에 다음 코드를 작성하자.

	```swift
	func processEvents(_ newEvents: [Event]) {
	    // 1
	    var updateEvents = newEvents + events.value
	    if updateEvents.count > 50 {
	        updateEvents = Array<Event>(updateEvents.prefix(upTo: 50))
	    }

	    events.value = updateEvents

	    // 2
	    DispatchQueue.main.async {
	        self.tableView.reloadData()
	        self.refreshControl?.endRefreshing()
	    }
	}
	```

	* `processEvent(_:)`는 view controller의 `event`라는 `Variable` 프로퍼티에 repository의 이벤트 리스트 중 최근 50개의 이벤트를 잡아서 저장한다. 여기서는 variable이나 subject를 바인드하는 법을 배우지 않았다는 가정하에 수동적인 방법으로 진행하였다.
	* 1) 새로 패치한 50개의 이벤트들을 `evnets.value`에 append 하였다. 이를 통해 최근의 활동만이 테이블 뷰에 표시되도록 할 수 있다. 이로써 UI에 업데이트할 `events` 값을 설정완료 하였다. 데이터 소스코드는 `ActivityController`에 이미 구현되어 있으므로 테이블뷰 리로드만 추가해주면 된다.
	* 2) 해당 부분은 UI에 관련한 부분이기 때문에 메인 쓰레드에서 작동해야 한다.

## D. 잠깐: 에러 입력 관리하기

* **Event.swift**의 `init`을 살펴보자. 서버의 객체가 잘못된 키이름을 가지고 온다면 어떻게 될까? 앱은 당연히 크래쉬날 것이다. 현재의 `Event` 코드로는 서버가 반드시 유효한 JSON을 보내주어야만 문제가 없다.
* 이를 수정하기 위해 `init`을 수정하자.

	```swift
	init?(dictionary: AnyDict)
	```

* 또한 `fatalError()` 부분을 다음과 같이 변경하자.

	```swift
	return nil
	```

* 이렇게 하면 여러군데에서 에러가 날 것이다. 걱정하지 말자. 이건 `map`과 `flatMap`의 차이를 한 번더 이해할 수 있는 기회다. 현재 `ActivityController`에서 JSON 객체를 `map(Event.init)`을 통해 이벤트로 변환하고 있다. 이러한 접근법으로는 `nil` 요소를 필터링 할 수 없다. 따라서 `Event.init`로 들어가는 `nil` 값을 필터하려면 `flatMap`을 쓸 수 있다. 여기서 주의점은 `Observable`에 `flatMap`을 쓰는게 아니라 `Array`에 쓴다는 것이다.
* `ActivityController.swift`의 `fetchEvents(repo:)`를 확인해보자. 여기서 `return objects.map(Event.init)`을 다음으로 변경하자.

	```swift
	return objects.flatMap(Event.init)
	```

* `nil`을 반환하는 `Event.init` 호출을 `flatMap`하면 `object`는 `nil` 값을 제거하게 된다. 따라서 `Event` 객체를 가지는 array(옵셔널아님)의 `Observable`을 얻을 수 있다.

## E. 디스크에 객체 두기

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/7.%20flow.png?raw=true" height = 300>

* 이 예제에서는 이벤트 저장을 `.plist`에 할 것이다. 저장할 객체양이 많지 않으므로 `.plist` 파일을 통한 저장이 적절하다. ~책에서는 Ch.21 "RxRealm" 에서 Realm을 통한 방법을 설명한다.~
* `ActivityController` 클래스에 다음과 같이 프로퍼티를 추가한다.

	```swift
	private let eventsFileURL = self.cachedFileURL("events.plist")
	```

* 프로퍼티에서 사용한 함수를 다음과 같이 클래스 바깥에 작성한다.

	```swift
	func cachedFileURL(_ fileName: String) -> URL {
	    return FileManager.default
	        .urls(for: .cachesDirectory, in: .allDomainsMask)
	        .first!
	        .appendingPathComponent(fileName)
	}
	```

* `processEvents(_:)`로 이동하여 하단에 다음 코드를 추가한다.

	```swift
	let eventsArray = updatedEvents.map{ $0.dictionary} as NSArray
	eventsArray.write(to: eventsFileURL, atomically: true)
	```

	* `updatedEvents`를 JSON 객체로 변환한다. 이는 .plist 파일에 저장하기에도 좋다. 그리고 이렇게 변환한 객체를 `NSArray` 객체인 `eventsArray`에 저장한다. Swift의 array와는 달리, `NSArray`는 내용을 파일에 곧바로 저장하는 매우 간단하고 직접적인 메소드를 제공한다. (~Array는 외않되?~)
	* array를 저장하기 위해 `write(to:atomically:)`를 파일 위치 URL과 함께 호출할 수 있다. 이 위치에서 파일이 생성되고 수정될 것이다.
* 파일에서 객체를 한번만 읽으면 되므로 `viewDidLoad()`에서 이 작업을 수행할 수 있다. 저장된 이벤트가 있는 파일이 있는지 확인하고, 있으면 `evevts`에 내용을 로드한다. 따라서 아래 코드를 `viewDidLoad()`의 `refresh()` 호출 이전에 구현하자.

	```swift
	let eventsArray = (NSArray(contentsOf: eventsFileURL) as? [[String: Any]]) ?? []
	events.value = eventsArray.flatMap(Event.init)
	```

	* 이 코드는 객체를 디스크에 저장하는 작업의 반대 버전이다. `init(contentsOf:)`를 통해 `plist`파일의 객체목록을 불러오고 이를 `Array<[String Any]>`로 캐스트하는데 사용할 `NSArray`를 생성한 것이다.
	* 그리고 `flatMap`을 이용하여 JSON을 `Event` 객체로 변환한 뒤, 실패한 놈들은 필터링 한다.

## F. 리퀘스트에 Last-Modified 헤더 추가하기

* `flatMap`과 `map`을 한 번 더 연습해봅시다. 그냥 얘네가 참 중요해여..
* 여기서는 이 전에 반입하지 않은 이벤트만 요청하도록 **GitFeed**를 최적화 할 것이다. 이렇게 하면 트래킹하는 repository가 아무도 fork, like 하지 않은 놈이라면 서버에서 빈 응답만 받을 것이다. 이렇게 하면 네트워크 트래픽과 처리 능력을 절약할 수 있다.
* 먼저 `ActivityController`에 파일을 저장하기 위해 새로운 프로퍼티를 추가한다.

	```swift
	private let modifiedFileURL = cachedFileURL("modified.txt")
	```

	* `Mon`, `30 May 2017 04:30:00 GMT` 같은 단일 문자열 저장에는 `.plist` 파일이 필요없다. 이러한 놈들은 `Last-Modified`라는 이름의 헤더 값으로, JSON 리스폰스와 함께 서버가 보내는 놈들이다. (이게 왜 필요하냐면) 이런 리스폰스를 받고 다음 리퀘스트를 보낼 때, 저 헤더와 같은 헤더를 서버에 보내야 한다. 이렇게함으로써 서버가 '아 이놈이 마지막으로 패치한 놈이군' 하고 알게 해주는 것이다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/8.%20server.png?raw=true" height = 180>

* 이벤트 목록에 대해 작성해봤듯이, `Last-Modified` 헤더를 추적하기 위해서 `Variable`을 사용할 것이다. 다음 코드를 추가하자.

	```swift
	private let lastModified = Variable<NSString?>(nil)
	```

	* `NSArray`를 쓴 것과 같은 이유로 `NSString`을 사용한다.
* 다음 코드를 `viewDidLoad()`의 `refresh()` 이전에 추가하자.

	```swift
	lastModified.value = try? NSString(contentsOf: modifiedFileURL, usedEncoding: nil)
	```

	* 만약 `Last-Modified` 헤더 값이 파일에 이미 저장되어있다면 `NSString(contentsOf:usedEncoding:)`은 텍스트를 가지는 `NSString`을 생성할 것이다. 그렇지 않으면 `nil`값을 반환한다.

* 에러 리스폰스를 필터링하자. `fetchEvents()`를 이동해서 `response` observable에 대한 두번째 구독 부분에 다음 코드를 추가하자.

	```swift
	.filter { response, _ in
	    return 200 ..< 400 ~= response.statusCode
	}
	```

* 이제 `filter`, `map`, (그리고 한번 더) `filter`를 이용해서 다음과 같은 작업을 해야한다.
	* `Last-Modified` 헤더를 포함하지 않는 모든 리스폰스 필터하기
	* 헤더의 값 취하기
	* 최종적으로, sequence를 한번 더 필터하고, 헤더 값을 고려하기
* 여기서는 하나의 `flatMap`을 이용하여 sequence를 쉽게 필터링 할 것이다. 다음 코드를 상기 내용에 추가하자.

	```swift
	.flatMap { response, _ -> Observable<NSString> in
	    guard let value = response.allHeaderFields["Last-Modified"] as? NSString else {
	        return Observable.empty()
	    }
	    return Observable.just(value)
	}
	```

* `guard`를 이용해서 리스폰스가 `NSString`으로 캐스팅 되는 값을 가지는 `Last-Modified`라는 이름의 HTTP 헤더를 가지고 있는지 확인할 수 있다. 만약 캐스팅이 가능하다면, 하나의 요소를 가지는 `Observable<NSString>`을 반환할 것이다. 그렇지 않다면 어떠한 값도 방출하지 않는 `Observable`을 반환할 것이다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/9.%20guard.png?raw=true" height = 300>

* 이제 필요한 헤더 값을 얻었으므로 `lastModified` 프로퍼티를 업데이트하고 디스크에 값을 저장할 차례다. 다음을 추가하자.

	```swift
	.subscribe(onNext: { [weak self] modifiedHeader in
	    guard let strongSelf = self else { return }
	    strongSelf.lastModified.value = modifiedHeader
	    try? modifiedHeader.write(to: strongSelf.modifiedFileURL, atomically: true, encoding: String.Encoding.utf8.rawValue)
	})
	.disposed(by: bag)
	```

	* 구독의 `onNext` 클로저 내에 `lastModified.value`를 최근의 데이터로 업데이트하고, 디스크에 저장할 수 있도록  `NSString.write(to:atomically:encoding)`을 호출한다.
* 이제 GitHub API에 리퀘스트 할 때 저장된 헤더 값을 사용해야 한다. `fetchEvents(ropo:)` 상단에 다음과 같이 `URLRequest`를 만들어내는 `map` 부분이 있을 것이다.

	```swift
	.map { url -> URLRequest in
	    return URLRequest(url: url)
	}
	```

* 이 부분을 다음의 코드로 대체하자.


	```swift
	.map { [weak self] url -> URLRequest in
	    var request = URLRequest(url: url)
	    if let modifiedHeader = self?.lastModified.value {
	        request.addValue(modifiedHeader as String, forHTTPHeaderField: "Last-Modified")
	    }
	    return request
	}
	```

* 상기 코드에는 추가적인 조건이 필요하다: 만약 `lastModified` 가 값을 가지고 있다면, 파일 로딩이나 JSON 패치 후 저장에 문제가 없을 것이다. 따라서 `Last-Modified` 헤더로 값을 추가하고 리퀘스트 할 수 있다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/10.%20lastModified.png?raw=true" height = 300>

* 이렇게 헤더를 추가함으로써 GitHub에게 이 헤더보다 오래된 이벤트에 대해서는 관심이 없다는 것을 알려줄 수 있다. 이 작업은 트래픽을 저장하지 않게 해줄 뿐만 아니라, 데이터를 반환하지 않기 때문에 GitHub API의 사용제한수를 증가하지 않는 효과도 있다.

## G. Challenges

### 최상단의 repository를 패치하고 피드하기

* 이 연습문제를 통해 `map/flatMap` 사용을 한 번 더 해볼 것이다.
* 주어진 repository에 대해 최근 활동을 매번 패칭하는 대신, 인기 급상승 Swift repository를 찾아서 여기서의 활동을 표시할 수도 있다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/11.%20top%20trending.png?raw=true" height = 120>

* 딱 봤을 때는 이 작업이 매우 복잡해 보이겠지만, 이 작업은 12줄의 코드면 해결 가능하다.
* 시작하기 전에, `fetchEvents(repo:)`의 `let response = Observable.from([repo])`를 다음과 같이 변경하자.

	```swift
	let response = Observable.from(["https://api.github.com/search/repositories?q=language:swift&per_page=5"])
	```

* 이 API 끝단에서는 가장 인기있는 Swift repository 중 상위 5개의 리스트를 반환할 것이다. 별도의 명령 파라미터를 입력하지 않고 API를 호출하였기 때문에 GitHub은 각 repository의 "score"(GitHub 자체의 연산 프로퍼티)를 통해 산출된 결과값을 반환할 것이다.
* 이제 String을 `URL`로 변환하고 이를 `URLRequst`로 변환하는 것과 똑같은 방식으로 진행되기 때문에 더이상 `Last-Modified` 헤더는 필요없다. 따라서 raw data 대신에 변형된 JSON을 바로 반환해주는 `URLSession.shared.rx.json(request:)` 메소드를 바로 사용할 수 있다.
* 그렇다면 필요한 것은 `[String:Any]` 형태의 JSON 리스폰스를 받아서 `items` key를 받는 것이다. `items`는 각각의 인기 repository를 보여주는 `[String:Any]` 타입의 목록을 가지고 있어야 한다. 우리는 이러한 repository들의 `full_name`이 필요하다.
* 앞서 실습한 것처럼 `flatMap`을 사용하여 실패할 경우 `Observable.empty()`를 반환하고, 성공할 경우 `Observable<String>`을 반환하도록 하자. 다음과 같이 표현할 수 있을 것이다.

	```swift
	func fetchEvents(repo: String) {
	//        let response = Observable.from(["repo"])
	    let response = Observable.from(["https://api.github.com/search/repositories?q=language:swift&per_page=5"])
	//            map to convert to to URLRequest
	//            flatMap to fetch JSON back
	//            flatMapt to convert JSON to list of repo names, and create Observable from that list
	//            existing code floows below
	        .map { urlString -> URL in
	            return URL(string: "https://api.github.com/repos/\(urlString)/events")!
	        }
	        ...
	```

* 이제 앱을 구동하고 테이블뷰를 pull to refresh 할 때마다 앱은 최근 가장 인기있는 5개의 Swift repository를 보여줄 것이며, 5개의 서로 다른 repository에서 발생하는 각각의 이벤트들을 패치하기 위해 GitHub에 서로 다른 리퀘스트를 보낼 것이다. 동일한 repository의 이벤트가 너무 많아지면 URL에 `per_page=5` 쿼리 매개변수를 추가하여 서버 응답을 제한 할 수 있다.

> A.
>
> ```swift
> // map to convert to to URLRequest
> .map { URL(string: $0)! }
> // flatMap to fetch JSON back
> .flatMap { url -> Observable<Any> in
>     let request = URLRequest(url: url)
>     return URLSession.shared.rx.json(request: request)
> }
> // flatMap to convert JSON to list of repo names, and create Observable from that list
> .flatMap { response -> Observable<String> in
>     guard let response = response as? [String:Any],
>         let items = response["items"] as? [[String:Any]] else { return Observable.empty() }
>     return Observable.from(items.map { $0["full_name"] as! String })
> }
> ```


***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
