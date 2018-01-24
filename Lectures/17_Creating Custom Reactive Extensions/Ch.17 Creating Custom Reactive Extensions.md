# Ch.17 Creating Custom Reactive Extensions

## A. 시작하기

* 이 장에서는 엔드포인트와의 통신을 관리하고 일반적으로 앱의 일부인 캐시 및 기타 사항을 관리하는 `NSURLSession`에 대한 extension을 생성할 것이다. 이 예는 교육 목적으로, 사실 RxSwift로 네트워킹을 사용하고 싶다면 RxAlamofire를 비롯한 다양한 라이브러리가 있다. 
* 예제를 위해 [Giphy](https://giphy.com)의 베타키가 필요하다. [키를 생성](https://developers.giphy.com/docs/)하고 해당 키를 **ApiController.swift**의 아래와 같은 위치에 입력한다.

	```swift
	private let apiKey = "[YOUR KEY]"
	```

## B. extension 생성하기

* Cocoa 클래스나 프레임워크로 extension을 만드는 것은 중요한 작업이다. 이번 예제를 진행하면서 이 과정이 까다롭다고 느끼게 될 것이다.
* 여기서의 목표는 `URLSession`을 `rx`로 확장하는 것이다. 

### 1. URLSession을 .rx로 확장하기

* **URLSession+Rx.swift**를 열고 다음과 같이 입력하자.

```swift
extension Reactive where Base: URILSession {

}
```

* `Reactive` extension은 아주 영리한 프로토콜 extension이다. 이 녀석은 `.rx` 키워드를 `URLSession`에 붙일 수 있게 해준다. 
* 이는 `URLSession`을 RxSwift로 확장하기 위한 첫 번째 과정으로, 이제 진짜 wrapper를 생성할 차례다.

### 2. wrapper method 생성하기

* 이제 `.rx` 키워드를 `NSURLSession`에 붙일 수 있으므로, data의 `Observable`을 반환할 wrapper 메소드를 생성할 수 있다.
* API는 다양한 타입의 data를 반환한다. 따라서 앱이 예측할 수 있는 데이터 타입을 체크하는 것이 좋다. 현재 앱에서는 다음과 같은 타입을 처리하는 wrapper를 만들고 싶다.
	* Data: 일반적인 데이터
	* String: 텍스트 형식의 테이터
	* JSON: JSON 객체 인스턴스
	* Image: 이미지 인스턴스
* 이러한 wrapper들은 각 타입의 데이터가 도착할 때까지 대기하게 된다. 만약 저 4가지 데이터 타입이 아닌 다른 형태의 데이터를 받으면 앱은 crashing 없이 에러를 내보낼 것이다.
* 제대로된 타입의 데이터를 받았다면, 이 wrapper는 `HTTPURLResponse`와 결과 `Data`를 반환한다. 이 예제에서의 목표는 다음과 같은 3개의 연산자를 이용해 `Observable<Data>`를 만들어내는 것이다. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/17_Creating%20Custom%20Reactive%20Extensions/1.createObservable.png?raw=true" height = 80>

* 주 response 함수의 골격을 작성해보자. 이렇게 하면 어떤 놈이 반환되어야 하는지 알 수 있다. 앞서 만들어 놓은 extension 안에 이 함수를 추가해보자.

	```swift
	func response(request: URLRequest) -> Observable<(HTTPURLResponse, Data)> {
		return Observable.create { observer in
			// content goes here
			return Disposables.create()
		}
	}
	``` 
	
	* extension이 어떤 것을 반환해야하는지는 분명하다. `URLResponse`는 요청이 `Data`의 반환을 받기까지 성공적으로 진행되는 것을 확인하기 위해 대기하게 된다.
* `URLSession`은 콜백과 `task`를 기반으로 한다. 예를 들면 요청을 보내고 서버의 응답을 받는 내장된 method인 `dataTask(with:completionHandler:)`를 들 수 있다. 이 함수는 결과 관리를 위한 콜백을 사용한다. 따라서 observable의 로직은 클로저 내부에서 관리되어야 한다. 이를 위해 다음과 같은 코드를 `Observable.create:` 내부에 생성하자. 

	```swift
	let task = self.base.dataTask(with: request) { (data, response, error) in
	    
	}
	task.resume()
	```
	
	* 생성된 task는 반드시 resume(또는 started)되어야 한다. 따라서 `resume()`은 요청을 trigger하게 된다. 결과는 콜백에 의해 처리된다.
	* **참고**: `resume()`함수의 사용은 "명령형 프로그래밍"으로 알려져 있다. 이에 대한 의미는 추후에 알게 될 것이다.* 
* 이전 블록에 `Disposable.create()`를 만들어 놓았다. 사실 이 녀석은 `Observable`이 disposed 되면 아무 것도 하지 않는다. 따라서 리소스 낭비를 방지하기 위해 이 녀석은 취소시키는 게 낫다. 따라서 다음과 같은 코드로 해당 부분을 대체하자.

	```swift
	return Disposables.create(with: task.cancel)
	``` 
	
* 이제 적절한 생명주기를 갖는 `Observable`이 만들어졌다. 이제 이 인스턴스로 이벤트를 보내기 전에 데이터가 제대로 반환되는지 확인해야 한다. 따라서 `task.resume()` 바로 위에 다음과 같은 코드를 추가하자.

	```swift
	guard let response = response, let data = data else {
	    observer.on(.error(error ?? RxURLSessionError.unknown))
	    return
	}
	
	guard let httpResponse = response as? HTTPURLResponse else {
	    observer.on(.error(RxURLSessionError.invalidResponse(response: response)))
	    return
	}
	```
	
	* 두 개의 `guard`문은 요청이 성공적으로 이뤄졌는지를 구독이전에 확인하는 역할을 한다.
* 모든 요청이 제대로 완료되었을 때, 해당 observable은 데이터를 필요로 하게 된다. 다음과 같은 코드를 상기 코드의 바로 다음에 추가하자

	```swift
	observer.onNext((httpResponse, data))
	observer.on(.completed)
	``` 
	
	* 이 코드들은 이벤트를, 뒤따르는 모든 구독에 보낸 뒤 completion된다. 
* 여기서, 요청을 보내고 해당 요청에 대한 응답을 받는 것은 `Observable`의 유일한 용도다. 따라서 observable이 (완전 종료되지 않고) 계속 살아있는 상태로 또다른 요청에 대해 작동하는 것은 말이 안된다. 이런 작동은 소켓 통신 같은 것에 더 적합하다.
* 이건 `URLSession`을 래핑하기 위한 아주 기본적인 작업이다. 아마 앱이 제대로된 데이터를 받았는지 확인하기 위해 더 많은 래핑이 필요할 것이다. 좋은 소식은, 이 메소드를 재사용할 수 있다는 것이다.
* `Data` 인스턴스를 반환하는 함수를 추가하자

	```swift
	func data(request: URLRequest) -> Observable<Data> {
	    return response(request: request).map { (response, data) -> Data in
	        if 200 ..< 300 ~= response.statusCode {
	            return data
	        } else {
	            throw RxURLSessionError.requestFailed(response: response, data: data)
	        }
	    }
	}
	
	func string(request: URLRequest) -> Observable<String> {
	    return data(request: request).map { d in
	        return String(data: d, encoding: .utf8) ?? ""
	    }
	}
	
	func json(request: URLRequest) -> Observable<JSON> {
	    return data(request: request).map { d in
	        return try JSON(data: d)
	    }
	}
	
	func image(request: URLRequest) -> Observable<UIImage> {
	    return data(request: request).map { d in
	        return UIImage(data: d) ?? UIImage()
	    }
	}
	```
	
	* 이와 같이 extension을 모듈화하면, 더 나은 합성이 가능하다. 예를들어 마지막 observable은 다음과 같은 과정으로 보여질 수 있다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/17_Creating%20Custom%20Reactive%20Extensions/2.flow.png?raw=true" height = 80>

* `map`과 같은 몇몇 RxSwift의 연산자들은 process overhead를 피하기 위해 알아서 적절히 조합되어 `map`의 다중 체인이 단일 호출로 최적화된다. 
	
### 3. 커스텀 연산자 만들기

* RxCocoa에 대한 챕터에서 캐시 데이터에 대한 함수를 만들었었다. GIF의 사이즈를 고려할 때 이는 좋은 접근법이 될 수 있다. 좋은 앱이라면 가능한 최대로 로딩시간을 줄이는 것이 좋다. ([캐시 데이터 함수 다시보기](https://github.com/fimuxd/RxSwift/blob/master/Lectures/14.%20Error%20Handling%20in%20Practice/Ch.14%20Error%20Handling%20in%20Practice.md#d-에러-잡아내기))
* `(HTTPURLResponse, Data)` 타입의 observable에서만 유효한 캐시 데이터를 위해 특별한 연산자를 만들어보자. 
* 목표는 가능한한 많이 캐시하는 것이므로 `(HTTPURLResponse, Data)` 타입의 observabled에 대해서만 이 연산자를 생성하고, 응답 객체를 사용하여 요청할 절대 URL을 dictionary의 키로 사용하는 것이 합리적이다. 
* 캐싱 전략은 단순한 `Dictionary`가 형태가 될것이다. 나중에 이 기본 동작을 확장하여 캐시를 유지하고 앱을 다시 열 때 리로드할 수 있다. 이 앱에서는 현재 범위로 충분히 커버 가능하다.
* `RxURLSessionError` 정의 전에 캐시 dictionary를 생성한다.

	```swift
	fileprivate var internalCache = [String: Data]()
	```

* `Data` observable만 타겟으로 할 extension을 생성한다.

	```swift
	extension ObservableType where E == (HTTPURLResponse, Data) {
	    func cache() -> Observable<E> {
	        return self.do(onNext: { (response, data ) in
	            if let url = response.url?.absoluteString, 200 ..< 300 ~= response.statusCode {
	                internalCache[url] = data
	            }
	        })
	    }
	}
	```
	
* 캐시를 사용하려면 응답 결과를 반환하기 전에 기존의 `data(request:)`의 `return` 부분을 수정하여 응답을 캐시해야 한다. 이를 위해 다음 코드와 같이 `.cache()` 문구를 삽입한다. 

	```swift
	return response(request: request).cache().map { (response, data) -> Data in
		//...
	}
	```

* 네트워크 요청을 매번 보내는 대신에 데이터가 이미 있는지 확인하기 위해서 다음 코드를 `data(request:)`상단의 `return` 이전에 삽입한다.

	```swift
	if let url = request.url?.absoluteString, let data = internalCache[url] {
		return Observable.just(data)
	}
	```
	
* 이제 확실한 한가지 타입에 대한 Observable로 확장하는 아주 기본적인 캐시 시스템을 완성했다. 다른 형식의 데이터를 캐시하기 위해 이 방법을 재사용할 수 있다.

<img src= "https://github.com/fimuxd/RxSwift/blob/master/Lectures/17_Creating%20Custom%20Reactive%20Extensions/3.cache.png?raw=true" height = 150>

## C. 커스텀 wrapper 사용하기

* `URLSession`을 감싸는 몇가지 wrapper를 만들어보았다. 또한 특정 유형의 observable만을 대상으로 하는 커스텀 연산자도 만들었다. 이제 이를 가지고 결과를 가져와서 귀여운 고양이 GIF를 보여줄 차례다. 필요한 것은 Giphy API에서 `JSON` structure 리스트를 가져오는 것이다.
* **ApiController.swift**를 열고 `search()` 메소드를 찾아보자. 해당 메소드 내부에는 Giphy API에 요청하기 위한 코드가 이미 작성되어 있지만, 가장 아랫 부분을 보면 네트워크 호출에 대한 부분이 없고 그저 빈 observable을 반환하고 있을 뿐이다.
* Rx `URLSession` extension을 이미 만들었기 때문에, 이를 이용하여 네트워크에서 데이터를 가져올 수 있다. `return` 부분을 다음과 같이 수정해보자.

	```swift
	return URLSession.shared.rx.json(request: request).map() { json in
		return json["data"].array ?? []
	}
	```
	
	* 이 코드는 주어진 query string을 위한 요청을 처리하지만 데이터는 여전히 표시되지 않는다. GIF를 화면에 띄우기 전 마지막으로 할 작업이 남아있다.
* 다음 코드를 **GifTableViewCell.swift**의 `downloadAndDisplay(gif stringUrl:)` 마지막 부분에 추가하자.

	```swift
	let s = URLSession.shared.rx.data(request: request)
	    .observeOn(MainScheduler.instance)
	    .subscribe(onNext: { imageData in
	        self.gifImageView.animate(withGIFData: imageData)
	        self.activityIndicator.stopAnimating()
	    })
	disposable.setDisposable(s)
	```
	
	* 작업을 제대로 수행하기 위해서는 `SingleAssignmentDisposable()`의 사용이 필수적이다. GIF 다운로드를 시작했을 때, 만약 사용자가 스크롤을 내려버리거나 이미지가 렌더링 되기까지 기다리지 않는다면 다운로드를 멈추도록 해야한다. 이를 구현하기 위해 `prepareForReuse()`에 하기 2줄의 코드가 이미 작성되어 있다.

	```swift
	disposable.dispose()
	disposable = SingleAssignmentDisposable()
	```
	
	* `SingleAssignmentDisposable()`은 하나의 셀에 하나의 구독만 가능하도록 보장하고, 이는 리소스 낭비를 막아준다.

## D. 커스텀 wrapper 테스트 하기

~Skip~
 
## E. 일반적인 wrapper 들

~skip~

### 1. RxDataSources
### 2. RxAlamofire
### 3. RxBluetoothKit


## G. Challenges
### processing feedback 추가하기

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com