# Ch.14 Error Handling in Practice

## A. 시작하기

* 이 장은 에러관리에 대해 배울 것이다. 에러가 발생했을 때 어떻게 복구하고 관리할지에 대해서.
* Ch.12 "Beginnig RxCocoa"에서 실습했던 예제와 이어질 것이다. 여기서 우리는 사용자의 현재 위치와 도시명 입력을 통해 해당 위치의 날씨를 받아올 수 있었다. 또한 activity indicator를 통해 진행상황을 눈으로 확인할 수도 있었다.
* **ApiController.swift**를 열어 다음 위치에 Api Key를 입력하자. 

	```swift
	let apiKey = BehaviorSubject(value: "[YOUR KEY]")
	```

## B. 에러 관리

* 에러는 어떤 앱이서든 불가피한 요소다. 누구도 에러가 발생하지 않는다고 장담할 수 없다. 따라서 항상 에러관리 메커니즘을 준비해야 한다. 
* 앱에서 발생하는 가장 흔한 에러들은 다음과 같다.
	* 인터넷 연결 없음: 아주 흔한 에러 중 하나다. 만약 앱이 인터넷 연결을 통해 데이터를 받아와야하는데 기기가 오프라인 상태가 된다면, 이를 감지하고 적절한 대응을 해줘야 한다.
	* 잘못된 입력: 때에 따라서 정해진 폼에 따라서 입력값이 필요한 경우가 있다. 하지만 사용자는 언제든지 잘못된 값을 입력할 수 있다. 전화번호 입력란에 숫자대신 글자를 입력하는 사용자는 언제나 있을 수 있다.
	* API 또는 HTTP 에러: API를 통한 에러는 아주 광범위하게 일어난다. 표준 HTTP 에러(400 또는 500 에러)를 통해 표시되거나 JSON 내 `status` 필드를 통해 표시될 수 있다. 
* RxSwift에서의 에러관리는 프레임워크 중 하나이며, 따라서 다음과 같이 두가지 방법으로 해결이 가능하다.
	* **Catch**: *기본값defaultValue*으로 error 복구하기

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/1.catch.png?raw=true" height = 50 >

	* **Retry**: 제한적 또는 무제한으로 *재시도Retry* 하기

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/2.retry.png?raw=true" height = 110>

* 이 장의 예제에는 실제 에러관리가 하나도 구현되어있지 않다. 모든 에러는 `dummy` 버전 데이터를 리턴하는 `catchErrorJustReturn` Single로 잡힌다. 이는 아주 유용해보이지만, RxSwift에는 더 나은 방법들이 있다. 
	
### 에러 던지기

* Apple의 프레임워크에 기반하여 시스템 에러를 래핑한 RxCocoa의 에러 관리부터 시작해보자. 
* **Pods/RxCocoa/URLSession+Rx.swift** 에서 다음 메소드를 찾아보자.

	```swift
	public func data(request: URLRequest) -> Ovservable<Data> { ... }
	```
	
	* 이 메소드는 `NSURLRequest`를 받아 `Data` 타입의 Observable을 반환한다. 여기서 주목해야할 점은 에러를 반환하는 코드 부분이다. 다음을 확인해보자.

	```swift
	if 200 ..< 300 ~= pair.0.statusCode {
		return pair.1
	}
	else {
		throw RxCocoaURLError.httpRequestFailed(response: pair.0, data: pair.1)
	}
	```
	
	* 이 다섯줄로 표현된 코드는 observable이 에러를 방출하는 방법을 보여주는 아주 좋은 예제다. 특히 사용자화한 에러까지 보여주고 있다.
	* 이 클로저 내에서는 `return`이 없다는 것을 상기하자. 만약 `flatMap` 연산자 내에서 발생한 에러를 내보내고 싶을 때, 기본 Swift 코드에서는 `throw`를 사용해야 한다. 이 것은 RxSwift를 사용하여 필요에 따라 일반적인 Swift 코드를 작성하는 방법, 그리고 필요에 따라 RxSwift 스타일의 오류 처리 방법을 보여주는 좋은 예가 된다.
	

## C. catch를 사용한 에러 관리

* 이제 에러를 어떻게 던지는지 확인했으니 이 에러를 어떻게 관리하는지 확인해보자. 기본적인 방법은 `catch`를 이용하는 것이다.
* `catch` 연산자는 기본 Swift에서 `do-try-catch` 구문을 통해 쓰였던 것과 비슷하다.
* observable이 실행되고 혹시 거기서 잘못된 점이 있으면 에러를 감싼 이벤트가 반환된다.
* RxSwift에는 `catch`계열에 두가지의 주요 연산자가 있다. 첫째는 다음과 같다.

	```swift
	func catchError(_ handler:) -> RxSwift.Observable<Self.E>
	```
	
	* 이 연산자는 클로저를 매개변수로 받아서 완전히 다른 형태의 observable로 반환한다.
	* 이 옵션을 어디서 사용해야할지 감이 잡히지 않는다면, observable 에러가 발생하면 이전에 캐싱된 값을 반환하는 전략을 생각해보자. 다음과 같은 과정을 거치게 된다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/3.catchError.png?raw=true" height = 100>

	* 여기서 `catchError`는 이전에 에러가 발생하지 않았던 값을 반환한다. 
* 두번째 연산자는 다음과 같다.

	```swift
	func catchErrorJustReturn(_ element:) -> RxSwift.Observable<Self.E>
	```
	
	* 이 연산자를 이전 장에서 사용해봤을 것이다. 이 연산자는 에러를 무시하고 이전에 선언해둔 값을 반환해준다.
	* 이 연산자는 `catchError`에 비해 제한적이다. 왜냐하면 `catchErrorJustReturn`은 주어진 유형의 에러에 대한 값을 반환할 수 없기 때문이다. 에러가 무엇이든 관계없이 모든 에러에 대해 동일한 값이 반환된다.

### 일반적인 문제

* 에러는 observable 체인을 통과하는 과정에서 발생한다. 따라서 observable chain의 시작부분에서 에러가 발생했을 때 별도의 관리를 하지 않은 경우 그대로 구독으로 전달되게 된다. 무슨 뜻이냐고? observable이 에러를 냈을 때, 에러 구독이 확인되고 이로 인해 모든 구독이 dispose 된다는 뜻이다. 따라서 observable이 에러를 냈을 때, observable은 반드시 완전종료되고 에러 다음의 이벤트는 모두 무시된다. 이것이 observable의 규칙이다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/4.errorout.png?raw=true" height = 200>
	
	* 네트워크가 에러를 만들어내고 observable sequence도 에러를 냈다.
	* 구독은 추후 업데이트를 방지하기 위해 UI 업데이트를 중단한다. 
* 이를 실제 앱에 적용시켜보자. `textSearch` observable 내의 `catchErrorJustReturn(ApiController.Weather.empty)`를 삭제하고 앱을 실행해보면 API는 404 에러를 낼 것이다. 여기서 404 에러의 의미는 사용자가 찾고자 하는 도시명을 API내에서 찾을 수 없다는 의미다. 아마 다음과 같은 문구를 콘솔에서 발견할 것이다.

	```swift
	"http://api.openweathermap.org/data/2.5/weather?q=goierjgioerjgioej&appid=[API-KEY]&units=metric" -i -v
	Failure (207ms): Status 404
	```
	* 이를 통해 404 에러를 받음으로써 검색기능이 멈출 것을 확인했다. 사실 이 방법은 사용자에게 제공할 수 있는 최선이 아니다.

## D. 에러 잡아내기

* 작업이 끝나면 빈 형식의 `Weather`를 반환하여 앱의 에러가 복구되도록하여 앱이 중단되지 않도록 한다.
* 이러한 방식의 에러관리는 다음과 같은 workflow로 표현할 수 있다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/5.workflow.png?raw=true" height = 200 >

* 이 방식도 훌륭하다. 하지만 만약 가능할 경우 앱이 데이터를 캐시해서 반환할 수 있다면 더 좋을 것이다.
* **ViewController.swift**를 열고 다음과 같이 간단한 dictionary 프로퍼티를 추가하자.

	```swift
	var cache = [String: Weather]()
	```
	* 이녀석은 일시적으로 캐시 데이터를 가지고 있을 것이다.
* `viewDidLoad()` 메소드로 가서 지난번에 만든 `textSearch` observable을 확인하자. `do(onNext:)`를 체인에 추가하는 것으로 `textSearch` observable을 변경하여 캐시를 채울 수 있다. 다음과 같이 코드를 작성하자.

	```swift
	        let textSearch = searchInput.flatMap { text in
	            return ApiController.shared.currentWeather(city: text ?? "Error")
	                .do(onNext: { data in
	                    if let text = text {
	                        self.cache[text] = data
	                    }
	                })
	                .catchErrorJustReturn(ApiController.Weather.empty)
	        }
	```
	
	* 이렇게 하면 제대로된 날씨 데이터들은 `cache` dictionary에 쌓일 것이다. 
* 그렇다면 이렇게 캐시된 결과는 어떻게 재사용할 수 있을까? 에러이벤트에 캐시된 값들을 반환하려면 `.catchErrorJustReturn(ApiController.Weather.empty)`를 하기 코드로 바꿔준다. 

	```swift
	.catchError { error in
		if let text = text, let cachedData = self.cache[text] {
			return Observable.just(cachedData)
		} else {
			return Observable.just(ApiController.Weather.empty)
		}
	}
	``` 
	
	* 테스트를 위해서 3,4개의 도시들을 입력해서 각 도시에 대한 날씨 값을 가져와보자. 그리고 나서 인터넷 연결을 끊은 다음 또 다른 도시를 검색해보자. 아마 에러를 받을 수 있을 것이다. 인터넷 연결을 끊은 상태로 처음에 가져온 값(3,4개 도시 입력을 통해. 아마 cache에 잘 저장되어있을 것임)을 불러오기 위해 기존의 도시를 입력해보자. 아마 가져온 값을 보여줄 것이다. 

## E. 에러 상황에서 재시도하기

* RxSwift에서는 `catch`뿐만 아니라 `retry`를 사용해서 에러를 관리할 수 있다.
* `retry` 연산자가 observable 에러에서 사용될 때, observable은 스스로를 계속 반복한다. 즉, `retry`는 observable 내의 *전체* 작업을 반복한다는 것을 의미한다.
* 이는 에러 발생시 사용자가 직접 (부적절한 타이밍에) 재시도 함으로써 사용자 인터페이스가 변경되는 부작용을 막기 위해 권장되는 방법이다. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/6.retryError.png?raw=true" height = 200>

### 1. Retry

* 이 연산자를 실험하기 위해 `catchError` 부분 전체를 주석처리 하자.

	```swift
	// .catchError { error in
	//  	if let text = text, let cachedData = self.cache[text] {
	//  	 return Observable.just(cachedData)
	//	 } else {
	//		 return Observable.just(ApiController.Weather.empty)
	//	 }
	// }
	```
	
* 이 자리에 `retry()`를 추가하고 앱을 샐행해보자. 인터넷 연결을 끊고 검색을 시도해보자. 아마 콘솔에 많은 메시지가 찍히는 것을 확인할 수 있을 것이다. 이는 앱이 계속 요청을 시도하는 것을 보여주는 것이다.
* 몇 초뒤 인터넷을 다시 연결해보자. 아마 앱이 성공적으로 결과값을 보여주는 것을 확인할 수 있을 것이다.
* `retry`계열에서 쓸 수 있는 두 번째 연산자는 다음과 같다.

	```swift
	func retry(_ maxAttemptCount:) -> Observable<E>
	```			
	* 이 연산자를 통해 몇번에 걸쳐서 재시도를 할 것인지 지정할 수 있다.
	* 실험을 위해 다음과 같이 코드를 변경해보자,.
		* `retry()`를 삭제한다.
		* 주석처리한 코드를 다시 활성화 한다.
		* `catchError` 전에 `retry(3)`을 삽입한다.
	* 수정을 완료하면 다음과 같을 것이다.

	```swift
	return ApiController.shared.currentWeather(city: text ?? "Error")
		.do(onNext: { data in
			if let text = text {
				self.cache[text] = data
			}
		})
			.retry(3)
			.catchError { error in
				if let text = text, let cachedData = self.cache[text] {
					return Observable.just(cachedData)
				} else {
					return Observable.just(ApiController.Weather.empty)
				}
			}
	```
	
	* 만약 Observable이 에러를 발생하면, 성공할 때까지 3번 반복할 것이다. 4번째 에러를 발생시킨 순간, 에러 관리를 멈추고 `catchError` 연산자로 이동될 것이다.  

### 2. 고급 retry 사용

* 마지막으로 살펴볼 `retryWhen` 연산자는 고급 재시도 상황에서 적절히 사용할 수 있다.

	```swift
	func retryWhen(_ notificationHandler:) -> Observable<E>
	```
	* 여기서 주목해야할 점은 `notificationHandler`가 `TriggerObservable` 타입이라는 것이다.
	* trigger observable은 `Observable` 또는 `Subject` 모두가 될 수 있다. 또한 임의적으로 retry를 trigger 하는데 사용된다.
* 이 방법은 이번 예제에서 인터넷 연결이 끊겼을 때 또는 API로 부터 에러를 받았을 때 사용되도록 이용할 수 있다. 만약 제대로 구현한다면 결과는 다음과 같이 나타날 것이다.

	```swift
	subscription -> error
	delay and retry after 1 second
	
	subscription -> error
	delay and retry after 3 seconds
	
	subscription -> error
	delay and retry after 5 seconds
	
	subscription -> error
	delay and retry after 10 seconds
	```
	
	* 기존 Swift에서 이러한 결과를 나타내려면 GCD등을 이용한 복잡한 코드가 필요하다. 하지만 RxSwift를 사용하면 짧은 코드 블록으로 가능하다.
	* 최종 결과를 만들기전에 유의해야할 것이 있다. 내부 observable 항목이 어떤 값을 반환해야하는지 확인해야하고, trigger가 어떤 유형이 될 수 있는지 고려해보아야 한다.
	* 작업 목적은 delay sequence와 함께 4번의 재시도를 하는 것이다. 먼저 `ViewController.swift` 내부에 `ApiController.shared.currentWeather` sequence 전에 `retryWhen` 연산자에서 사용할 최대 재시도 횟수를 정의하자.

	```swift
	let maxAttempts = 4
	```
	
	* 여기서 정의한 횟수만큼 재시도가 된 이후에 에러가 전달될 것이다.
* 이제 `.retry(3)`부분을 아래와 같이 수정하자.

	```swift
	// 1
	.retryWhen{ e in
		// 2. flatMap source errors
		return e.enumerated().flatMap { (attempt, error) -> Observable<Int> in
			// 3. attemp few times
			if attempt >= self.maxAttempts - 1 {
				return Observable.error(error)
			}
		return Observable<Int>.timer(Double(attempt + 1), scheduler: MainScheduler.instance).take(1)
		}
	}
	```
	
	* 1. 이 observable은 원래 에러를 반환하는 observable과 병합되어야 한다. 따라서 에러가 이벤트로 도착했을 때, 이 observable들의 병합은 현재 index를 포함하는 이벤트로 받아져야한다.
	* 2. 이 작업은 `enumerated()`를 호출하고 `flatMap`을 이용하여 해결할 수 있다. `enumerated()` 메소드는 기존의 observable의 값과 index를 가지는 tuple의 observable을 새로운 observable로 반환한다.
	* 3. 이제 원래의 에러 observable과 재시도 이전에 얼마나 지연되야하는지를 정의한 observable이 결합되었다. 이제 이 코드를 `timer`와 결합하자. 
 * 상기 코드가 잘 작동하는지 확인하려면 다음 코드를 `flatMap`내부 두 번째 `return` 이전에 입력한다. 
 
	```swift
	print("== retrying after \(attempt + 1) seconds ==")
	```

* 이 동작과정은 다음과 같다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/7.retry.png?raw=true" height = 300>

	* trigger는 원래의 에러 observable을 고려하여 아주 복잡한 back-off 전략을 쓸 수 있다. 몇 줄의 RxSwift 코드 만으로도 복잡한 오류 처리 전략을 작성할 수 있도록 한다. 

## F. 에러 사용자화

### 1. 사용자화 에러 만들기

* RxCocoa로부터 반환되는 에러는 상당히 일반적인 내용들이다. 따라서 HTTP 404 에러(page not found)는 502 에러(bad gateway)처럼 취급된다. 이 두가지는 완전히 다른 내용의 에러이기 때문에 다르게 처리해주는 것이 좋다.
* **ApiController.swift**를 자세히 파봤다면, 여기에 두가지 에러 케이스가 이미 포함되어 있는 것을 확인했을 것이다. 따라서 이 두개의 다른 HTTP 반응에 따라 다른 에러 처리를 해줄 수 있다.

	```swift
	enum ApiError: Error {
		case cityNotFound
	   	case serverFailure
	}
	```
* 이 에러 타입을 `buildRequest(...)` 내부에 사용하게 될 것이다. 이 메소드의 마지막 라인은 data의 observable을 반환하는 내용이다. 이 observable은 JSON 객체 structure에 매핑된다. 이 곳이 바로 커스텀 에러를 만들고 반환해야할 곳이다. 
* `buildRequest(...)` 내의 마지막 `flatMap` 블록을 다음의 코드로 대체하자.

	```swift
	return session.rx.response(request: request).map() { response, data in
		if 200 ..< 300 ~= response.statusCode {
			return try JSON(data: data)
		} else if 400 ..< 500 ~= response.statusCode {
			throw ApiError.cityNotFound
		} else {
			throw ApiError.serverFailure
		}
	}
	```
	
	* 이 메소드를 사용하면, 커스텀 에러를 만들 수 있고 API가 JSON을 통해 주는 메시지를 가지고 추가적인 로직을 구성하는 것도 가능하다. 
	* `JSON` 데이터를 받아서 `message` 영역의 내용을 통해 에러를 캡슐화 할 수 있다. 에러는 Swift의 강력한 기능중 하나이며, RxSwift에서는 더더욱 강력한 기능이 될 수 있다.

### 2. 사용자화 에러 사용하기

* **ViewController.swift**로 돌아가서 `retryWhen {...}` 부분을 확인하자. 여기서 우리가 하고 싶은 것은 에러가 observable 체인을 통과하면서 observable처럼 취급되는 것이다.
* 또 여기에는 `InfoView`라는 이름의 작은 뷰가 있다. 발생된 에러메시지를 앱 하단에 표시해주는 역할을 한다. 사용을 위해서 짧은 한 줄의 코드만 추가하면 되지만, 이 작업은 추후에 하도록 하자.
* 에러는 보통 retry나 catch 연산자로 처리된다. 하지만 부수작용을 발생시키고 싶거나 사용자 인터페이스에서 메시지를 띄우고 싶다면 `do` 연산자를 사용할 수 있었다. `retryWhen`을 사용할 때도 마찬가지로 `do`를 사용할 수 있다.
	
	```swift
	.do(onNext: { data in
		if let text = text {
			self.cache[text] = data
		}
	}, onError: { [weak self] e in 
		guard let strongSelf = self else { return }
		DispatchQueue.main.async {
			InfoView.showIn(viewController: strongSelf, message: "An error occurred")
		}
	})
	```
	* 여기서 dispatch가 필요한 이유는 sequence가 background 쓰레드에서 관찰되고 있기 때문이다. 그렇지 않으면 UIKit은 UI가 background 쓰레드에서 수정되고 있는 것에 대해서 경고를 보낼 것이다.
* 여기에 단순히 한가지 에러메시지 외에 다른 메시지를 더 보내고 싶다면 다음과 같이 작성해보자.

	```swift
	func showError(error e: Error) {
		if let e = e as? ApiController.ApiError {
			switch (e) {
			case .cityNotFound:
				InfoView.showIn(viewController: self, message: "City Name is invalid")
			case .serverFailure:
				InfoView.showIn(viewController: self, message: "Server error")
			}
		} else {
			InfoView.showIn(viewController: self, message: "An error occurred")
		}
	}
	``` 

## G. 고급 에러 처리

* 고급 에러 처리는 도입하기에 까다로울 수 있다. 왜냐하면 사용자에게 메시지를 보내는 것과는 별개로, API가 에러를 반환했을 때 별도로 취해야할 일반적인 규칙 같은 것은 없기 때문이다. 
* 현재 앱에서 인증 기능을 추가한다고 생각해보자. 사용자는 날씨 정보를 요청하기 위해 인증을 거쳐야 한다. 아마 이를 통해서 사용자가 제대로 로그인 했는지 확인할 세션이 생성될 것이다. 하지만 세션이 만료되었다면 어떻게 해야할까? 에러를 반환하거나 빈 값을 반환해야할까?
* 이 상황에 대한 특책은 없다. 여기에는 두가지 해결책을 구현해놓았지만 이건 에러를 이해하기에 유용한 해결책일 뿐, 그 이상의 정답은 아니다. 
* `apiKey`라는 behaviorSubject를 사용해보자. 이 녀석은 `retryWhen`클로저를 retry할 trigger로 사용될 수 있다.
* API 키의 유실은 에러로 정의될 수 있다. 따라서 다음 케이스를 `ApiError` enum에 추가하자.

	```swift
	case invalidKey
	```
	
* 이 에러는 서버가 401 코드를 반환했을 때 발생해야 한다. `buildRequest(...)` 함수에 이 에러를 내자. 위치는 첫번째 if 조건인 `200 ..< 300` 바로 다음이 될 것이다.

	```swift
	else if response.statusCode == 401 {
		throw ApiError.invalidKey
	}
	```

* 새로운 에러는 새로운 handler도 필요로 한다. **ViewController.swift**의 `showError(error:)`내부의 `switch` 메소드에 다음과 같은 코드를 추가한다.

	```swift
	case .invalidKey:
		InfoView.showIn(viewController: self, message: "Key is invalid")
	```
* `searchInput`을 구독하기 전에 에러처리를 할 별도의 클로저를 observable 체인 바깥에 생성하자. 

	```swift
	 let retryHandler: (Observable<Error>) -> Observable<Int> = { e in
	 	return e.enumerated().flatMap { (attempt, error) -> Observable<Int> in
	 		if attempt >= maxAttempts - 1 {
	 			return Observable.error(error)
	 		} else if let casted = error as? ApiController.ApiError, casted == .invalidKey {
	 			return ApiController.shared.apiKey
	 				.filter { $0 != "" }
	 				.map { _ in return 1 }
	 		}
	 		print("== retrying after \(attempt + 1) seconds ==")
	 		return Observable<Int>.timer(Double(attempt + 1), scheduler: MainScheduler.instance)
	 			.take(1)
	 	}
	 }
	```
	
* 그리고 `retryWhen` 부분을 다음과 같이 변경한다.

	```swift
	retryWhen(retryHandler)
	```
	
* apiKey도 다음과 같이 변경한다.

	```swift
	let apiKey = BehaviorSubject(value: "")
	```
	
* 앱을 구동해서 날씨를 검색하면 에러 메시지가 뜨는 것을 확인할 수 있다. 이후 적절한 apiKey를 입력하고 나면 잘 구동되는 것을 확인할 수 있다.


### Materialize/dematerialize

* 에러 처리는 달성하기 어려운 작업일 수 있다. 때로는 흐름을 더 잘 이해하기 위해서 실패한 sequence를 디버깅 해야한다. 
* 또 다른 어려운 상황은 third party 프레임워크에 의해 생성된 것과 같이, sequence 제어가 제한되거나 제어가 불가능해서 발생할 수도 있다. RxSwift는 이러한 상황에 대한 해결책을 제공하며, `materialize`및 `dematerialize`를 통해 해결할 수 있다.
* 책의 첫부분에서 `Event` enum에 대해서 배웠다. ([다시보기](https://github.com/fimuxd/RxSwift/blob/master/Lectures/01_HelloRxSwift/Ch.1%20Hello%20RxSwift.md#1-observables)) `Event`는 RxSwift의 아주 기본적인 요소이자 중요한 요소라고 할 수 있지만, 이들을 직접 사용하는 경우는 드물다. 
	* `materialize` 연산자는 어떤 sequence든 `Event<T>` eunm sequence로 변환한다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/8.materialize.png?raw=true" height = 200>
	
		* 이 연산자를 이용하면 적절한 연산자와 여러가지 handler로 조작되는 암시적인 sequence들을 명시적으로 변환할 수 있다. 따라서 `onNext`, `onError`, `onCompleted`는 각각의 함수로써 조작될 수 있다.
	* notification sequence를 뒤집고 싶으면 `demeterialize`를 사용할 수 있다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/9.demeterialize.png?raw=true" height = 200>
			
		* 이 연산자는 notification sequence를 일반 `Observable`로 변환한다. 
* 이 두가지 연산자를 병합해서 커스텀한 이벤트 기록기를 만들 수 있다. 

	```swift
	observableToLog.materialize() 
		.do(onNext: { (event) in 
			myAdvancedLogEvent(event)
		})
		.dematerialize()
	``` 	
	
* **참고**: `materialize`와 `dematerialize`는 보통 함께 쓰인다. 이 둘을 함께 쓰면 원본 observable을 완전히 분해할 수 있다. 다만, 특정 상황을 처리할 수 있는 다른 옵션이 없을 때만 신중하게 사용해야 한다. 	 
## I. Challenges
### 연결 재개를 위해 retryWhen 사용하기

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
