# Ch.6 Filtering Operators in Practice

*  연산자들은 `Observable<E>` 클래스상의 간단한 메소드들이며, 이 중 몇몇은 `Observable<E>`가 채택하는 `ObservableType` 프로토콜에 정의되어있다.
*  연산자들은 `Observable` 클래스 요소들을 조작하고 결과로써 새로운 observable sequence를 만들어낸다. 이는 아주 편리한데 그 이유는, 여러개의 연산자들을 **연결chain**하여 sequence 내에서 여러가지 작동을 할 수 있기 때문이다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/1.%20operators.png?raw=true" height = 300>

## A. Combinestagram 프로젝트 개선하기

* Ch.4 "Observable and Subject in Practice"에서 다뤘던 Combinestagram 예제를 이어서 개선해보자.

### photos sequence 다듬기

* 현재 앱의 메인화면은 다음과 같다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/2.%20currentMain.png?raw=true" height = 300 >

* 지금처럼 사용자가 콜라주에 사진 배치를 추가하면 매번 미리보기를 재생성하는 것 이상의 작업을 할 것이다.
* 예를들어 Observable한 사진들이 생성 완료되면, 사용자는 기본 화면으로 돌아가서 켜기/끄기, 라벨 업데이트 등을 할 수 있을 것이다. 같은 `Observable` 인스턴스에 대한 구독을 공유해서 더 많은 일을 수행하는 방법에 대해 살펴보자.

## B. 구독 공유하기

* `subscribe(...)`을 하나의 observable에 여러번 호출했을 때 문제가 있을까?
* 앞서 설명했듯이 observable은 lazy하고, pull 구동하는 sequence다. 따라서 사실 `Observable`에 여러개의 연산자를 호출하는 것은 실제 아무 일도 발생시키지 않는다. `subscribe(...)`을 호출한 순간이 `Observable`을 깨워서 요소들을 만들기 시작하도록 하는 것이다. 따라서 observable은 자신이 구독될 때마다 `create` 클로저를 호출한다.
* 아래 코드를 playground에서 구동해보자.

	```swift
	let numbers = Observable<Int>.create { observer in
		let start = getStartNumber()
		observer.onNext(start)
		observer.onNext(start+1)
		observer.onNext(start+2)
		observer.onCompleted()
		return Disposables.create()
	}
	```

	* 이 코드를 통해 `srart`, `start+1`, `start+2` 라는 세 개의 숫자를 만들어내는 `Observable<Int>` sequence가 생성되었다.
* 이제 `getStartNumber()`의 구조를 살펴보자.

	```swift
	var start = 0
	func getStartNumber() -> Int {
		start += 1
		return start
	}
	```

	* 이 함수는 변수를 증가시키고 반환한다. 특별히 잘못된 것이 없어보이는데 정말 그럴까? `number`를 구독하고 살펴보자.

	```swift
	numbers
		.subscribe(onNext: { el in
			print("element [\(el)]")
		}, onCompleted: {
			print("------------")
	})

	/* prints:
	 element [1]
	 element [2]
	 element [3]
	 ------------
	*/
	```

* 예상대로 잘 찍히는 것을 알 수 있다. 그렇다면 상기 구독을 복붙해서 한번더 실행해보자. 이 때 결과값은 달라진다.

	```swift
	/* prints:
	 element [1]
	 element [2]
	 element [3]
	 ------------
	 element [2]
	 element [3]
	 element [4]
	 ------------
	*/
	```

* 문제는 `subscribe(...)`을 호출할 때마다 구독을 위한 새로운 `Observable`이 생성된다는 것이다. 그리고 각각의 복사본이 이전 결과와 같다는 것을 보장하지 않는다. 심지어 `Observable`도 같은 요소의 sequence를 생성하지 않는다. 각각의 구독에 대해 동일한 중복 요소를 생성하는 것은 비생산적이다.
* 이러한 불필요한 행위를 방지하고 구독을 공유하기 위해서 `share()` 연산자를 사용한다. Rx 코드의 일반적인 패턴은 하나의 소스 `observable`의 각 결과 값에서 나오는 요소들을 필터링해 여러 개의 sequence들을 생성하는 것이다.
* Combinestagram을 이용하여 `share()`를 사용해보자.
* **MainViewController.swift**의 `actionAdd()` 함수내의 `photosViewController.selectedPhotos`를 아래의 코드로 바꾸자.

	```swift
	let newPhotos = photosViewController.selectedPhotos
	    .share()

	newPhotos
	```

* 아래 그림과 같이 observable에 대해 각각 구독하는 대신에,

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/3.%20previous.png?raw=true" height = 100>

* 아래 그림 처럼 하나의 `Observable`을 `share()`하여 여러 번 구독할 수 있다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/4.%20share.png?raw=true" height = 100>

* 다음 과정으로 넘어가기전에 `share`에 대해서 좀 더 알아보자.
* `share`는 구독자의 수가 0에서 1로 될 때만 구독을 생성한다. 두 번째, 세 번째 그리고 구독자들이 sequence를 관찰하기 시작할 때, `share`는 이미 생성한 구독을 사용하여 추가 구독자들과 공유한다. 만약 공유된 sequence에 대한 모든 구독이 dispose 되면 (예를 들어, 더 이상의 구독자가 없는 경우), `share`는 *공유된 sequence 또한 dispose 한다*. 다른 가입자가 다시 관찰을 시작하면 `share`는 *새로운* 구독을 생성한다.
	* **참고**: `share()`는 구독이 영향을 받기 전까지는 어떠한 값 방출도 내지 않는다. 반면에 `share(replay:scope:)`은 마지막 몇개의 방출 값에 대한 버퍼를 가지며 새로운 관찰자가 구독했을 때 이를 제공해준다.
* sharing 연산자는 complete 되지 않는 observable에 사용하기에 안전하다. complete 후에 새로운 구독이 수행되지 않는다고 보장할 수 있다. Ch.8 "Transforming Operations in Practice."에서 이에 대해 자세히 배울 수 있다.

### 1. 모든 요소 무시하기

* 모든 요소들을 필터하는 `ignoreElements()` 연산자를 다뤄보자. 값이나 타입에 상관없이 "넌 통과 못해!"라고 외치는 놈이다.
* `newPhotos`는 사용자가 사진을 선택할 때마다 `UIImage` 요소를 방출한다. 여기서는 화면 왼쪽 상단에 작은 미리보기를 추가할것이다. 이 아이콘을 한 번만 업데이트할 것이기 때문에 사용자가 main view controller로 돌아오면 모든 `UIImage` 요소들을 무시하고 `.completed` 이벤트에서만 작동해야 한다.
* `ignoreElements()`는 소스 observable에서 방출하는 모든 요소들을 무시하고, `.completed`나 `.error`만 통과하게 한다.
* `MainViewController`내부에 `updateNavigationIcon()` 함수를 추가하고 `actionAdd()`의 마지막 부분에 아래 코드를 추가하자.

	```swift
	newPhotos
	    .ignoreElements()
	    .subscribe(onCompleted: { [weak self] in
	        self?.updateNavigationIcon()
	    })
	    .disposed(by: photosViewController.bag)

	// ...

	private func updateNavigationIcon() {
	    let icon = imagePreview.image?
	        .scaled(CGSize(width: 22, height: 22))
	        .withRenderingMode(.alwaysOriginal)

	    navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
	}
	```

	* 앱을 구동하고 새로운 콜라주를 만들어보자. 사진추가 후 되돌아와보면 작은 미리보기를 왼쪽 상단에서 확인할 수 있다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/5.%20preview.png?raw=true" height = 300>

### 2. 필요 없는 요소들 필터링하기

* 모든 요소들을 필터링하는 `ignoreElements()` 외에 몇 가지의 요소만 필터링하고 싶을 때 사용할 수 있는 `filter(_:)` 연산자가 있다. 예를 들어 사진이 세로보기 형태라면 조합했을 때 잘 맞지 않을 것이다. 따라서 세로보기 사진은 필터링해보자.
* `actionAdd()`의 `newPhotos`에 대한 첫 번째 구독을 대해 다음과 같이 `filter`를 삽입하자.

	```swift
	.filter { newImage in
	    return newImage.size.width > newImage.size.height
	}
	```

	* 이제 `newPhotos`가 방출하는 각각의 사진들은 구독되기 전에 `filter`를 거치게 된다. 여기서는 사이즈를 확인해서 가로길이가 세로길이보다 긴 사진만 통과하도록 했다.

### 3. 고유한 filter 구현하기

* 지금의 Combinestagram에선 똑같은 사진을 여러번 추가하여 콜라주를 만들 수 있지만, 지금부터는 같은 사진을 여러번 추가하는 것을 필터링하여 서로 다른 사진만을 조합하게 하고 싶다.
* Observable들은 현재 상태나 값 히스토리를 제공하지 않는다. 그러므로 특정 요소를 확인하기 위해서는 어떻게든 각각의 요소 자체가 스스로를 추적하게 할 필요가 있다.
* 동일한 이미지를 나타내는 두개의 `UIImage` 객체가 동일하지 않기 때문에, 방출된 이미지의 인덱스를 저장하는 것은 도움이 되지 않는다. 따라서 가장 좋은 해결책은 이미지 데이터의 해시나 URL asset을 저장하는 것이다. 하지만 여기서는 간단한 연습을 위해 이미지의 byte 길이를 이용해볼 것이다.
* `MainViewController` 클래스에 다음과 같은 새로운 프로퍼티를 추가하자.

	```swift
	private var imageCache = [Int]()
	```

	* 각각의 이미지 byte 길이를 이 array에 저장할 것이다. 위에서 `filter`를 추가한 곳 바로 아래에 또 다른 `filter`를 추가하자.

	```swift
	.filter { [weak self] newImage in
		let len = UIImagePNGRepresentation(newImage)?.count ?? 0
		guard self?.imageCache.contains(len) == false else { return false }
		self?.imageCache.append(len)
		return true
	}
	```

	* 이 코드를 통해 새로운 이미지의 PNG 데이터의 byte 수를 상수 `len`으로 저장할 수 있다. 만약 `imageCache`가 같은 값을 이미 가지고 있다면 중복 이미지라 판단하고 `false`를 반환할 것이다.
* 구현한 기능을 래핑하기 위해 다음을 `actionClear()`에 추가하자.

	```swift
	imageCache = []
	```

	* 이를 통해 한 번 콜라주를 생성하고 다시 새로운 콜라주를 생성하려고 할 때는 캐시가 비워져서 사진을 재사용할 수 있게 될 것이다.

### 4. 조건에 부합하는 동안 요소들 취하기

* Combinestagram의 가장 큰 버그는 사용자가 6개의 사진을 추가했을 때 main view controller의 + 버튼이 비활성화 되는 것이다. 이는 애초에 6개를 초과하는 이미지를 추가할 수 없게 처리해 놓았기 때문인데 photo view controller에서는 여전히 사진을 계속 추가할 수 있다. 여기서도 제한을 둬야할 것으로 보인다.
* `takeWhile(_)` 연산자를 통해 모든 요소들이 확실한 조건에 부합했을 때만 필터링하도록 설정할 수 있다. Boolean 조건을 제공하고 `takeWhile(_)`은 조건이 `false`일 때의 모든 요소를 무시하게 하는 것이다.
* `actionAdd()`로 돌아가서 `newPhotos`의 첫 번째 구독 부분 바로 아래에 다음 코드를 추가하자.

	```swift
	newPhotos
		.takeWhile { [weak self] image in
		    return (self?.images.value.count ?? 0) < 6
		}
	```

	* `takeWhile(...)`은 이미지의 총 개수가 6보다 작을 동안만 이미지를 통과시킨다.
	* 만약 `self`가 `nil`일 때는 기본값 `0`을 줄 수 있도록 `??` 연산자를 사용한다.   

## C. 사진 선택 개선하기

* **PhotosViewController.swift**에서 새로운 `Observable`을 생성하고 새로운 방법으로 필터하여 화면의 UX를 개선할 것이다.

### 1. PHPhotoLibrary 인증 observable

* Combinestagram을 처음 사용할 때, 본인의 사진 라이브러리 접속을 허용했을 것이다. 이렇게 접속허용을 묻는 것은 앱을 최초에 구동했을 때 단 한번만 일어난다. 그러므로 여기서 관련 부분을 다시 확인해보기 위해 시뮬레이터를 리셋하고 시작하자.
* **PHPhotoLibrary+rx.swift** 라는 새로운 이름의 파일을 생성하고 다음 코드를 입력하자.

	```swift
	import Foundation
	import Photos
	import RxSwift

	extension PHPhotoLibrary {
	    static var authorized: Observable<Bool> {
	        return Observable.create { observer in

	            return Disposables.create()
	        }
	    }
	}
	```

	* 사용자가 접근을 허가 했는지 여부에 따라 두가지 방향으로 진행될 수 있다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/6.%20Where.png?raw=true" height = 200>

* 플로우차트를 `return Disposables.create()` 상단에 코드로 표현해보자.

	```swift
	DispatchQueue.main.async {
	    if authorizationStatus() == .authorized {
	        observer.onNext(true)
	        observer.onCompleted()
	    } else {
	        observer.onNext(false)
	        requestAuthorization { newStatus in
	            observer.onNext(newStatus == .authorized)
	            observer.onCompleted()
	        }
	    }
	}
	```

### 2. 접근 허용되었을 때 사진들 리로드하기

* 사진 라이브러리 접근에는 두가지 시나리오가 있다.
	* 하나는 alert이 떴을 때, 사용자가 **OK** 버튼을 누르는 것

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/7.%20first.png?raw=true" height = 50>

	* 다른 하나는 이미 허용한 다음에 접근한 경우

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/8.%20second.png?raw=true" height = 50>

* 첫 번째 경우: `PHPhotoLibrary.authorized.true`를 구독하는 것이다. 이는 특정 sequence의 마지막 요소일 수 있다. 따라서 `true` 요소를 얻을 때마다 컬렉션을 리로드하고 화면에 카메라롤 사진을 표시할 수 있다.
* 아래 코드를 **PhotosViewController.swift**의 `viewDidLoad()`에 추가하자.

	```swift
	let authorized = PHPhotoLibrary.authorized
	    .share()

	authorized
	    .skipWhile { $0 == false }
	    .take(1)
	    .subscribe(onNext: { [weak self] _ in
	        self?.photos = PhotosViewController.loadPhotos()
	        DispatchQueue.main.async {
	            self?.collectionView?.reloadData()
	        }
	    })
	    .disposed(by: bag)
	```

	* `skipWhile(_:)`: `true`가 나오기 전까지는 `false`들을 무시한다.
	* `take(1)` `true`가 필터링되어 나오면, 하나의 요소를 받은 뒤 그 뒤에 나오는 아이들은 무시한다.
* 두 번째 경우: 항상 `true`가 마지막 요소이기 때문에 `take(1)`를 쓸 필요가 없다. 하지만 `take(1)`를 사용하면 명확하게 의도를 표현할 수 있다. 권한 메커니즘이 나중에 변경된 경우에도 구독은 원하는대로 계속 수행된다. 첫 번째 `true` 요소에서 컬렉션뷰를 리로드하고 이후에 오는 내용은 무시한다.
* `subscribe(...)` 클로저 내부에서는 콜렉션뷰를 리로드 하기 전에 메인 쓰레드로 전환한다. 왜 이런 작업을 해야할까?`PHPhotoLibrary.authorized` 소스 코드를 살펴보면, 사용자가 접근을 허용하기 위해 **OK** 버튼을 누른 이후에 `true` 값이 방출되는 곳임을 알 수 있다.

	```swift
	requestAuthorization { newStatus
		observer.onNext(newStatus == .authorized)
	}
	```

	* `requestAuthorization(_:)`은 *어떤* 쓰레드에서 클로저가 실행을 완료할지 보장하지 않는다. 따라서 이는 background 쓰레드로 가게 될 것이다. 같은 쓰레드에서 observable에 대한 모든 구독 코드에 `onNext(_:)`를 호출하면 구독내에서 `self?.collectionView?.reloadData()`가 호출될 것이며 이 때 여전히 background 쓰레드에 있다면, UIKit은 크래시를 발생시킬 것이다. UI를 업데이트는 반드시 메인 쓰레드에서 이루어져야 한다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/9.%20UI%20thread.png?raw=true" height = 250>

### 3. 사용자가 접근을 허용하지 않았을 때 에러메시지 표시하기

* 다음과 같은 상황도 발생가능하다.
	* 최초 1회 앱 실행시 사용자가 접근을 허용하지 않았을 때

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/10.%20third.png?raw=true" height = 50>

	* 이후에도 계속 접근은 허용되지 않을 것이다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/11.%20fourth.png?raw=true" height = 50>

* 두 가지 경우 모두 sequence 요소는 같다. 왜냐하면 같은 코드 경로를 따르기 때문이다. 따라서 다음 두개의 로직을 생각할 수 있다.
	* sequence에서 방출하는 첫 번째 element는 무조건 무시할 수 있다. 왜냐하면 라이브러리 접근 허용 상태가 결정되지 않았을 때도 무조건 false 가 반환 될 것이기 때문이다. 이후 2번째 부터 반환되는 true or false 값이 직접 사용자가 alert를 통해 접근 허용 또는 거절한 상태가 된다.
	* sequence의 마지막 요소가 `false`인지 확인한다. 맞다면 에러 메시지를 표시한다.
* 이 내용을 `viewDidLoad()`에 추가하자

	```swift
	authorized
	    .skip(1)
	    .takeLast(1)
	    .filter { $0 == false }
	    .subscribe (onNext: { [weak self] _ in
	        guard let errorMessage = self.errorMessage else { return }

	        DispatchQueue.main.async(execute: errorMessage)
	})
	.disposed(by: bag)
	```

	* **참고**: `filter {$0 == false}`는 `filter {!$0}`로 축약될 수 있고 이는 `filter{!}`로 축약될 수 있다.
* `errorMessage`를 구현해야 하므로 `PhotoViewController` 내부에 다음 코드를 추가한다.

	```swift
	private func errorMessage() {
	    alert(title: "No access to Camera Roll", text: "You can grant access to Combinestagram from the Settings app")
	        .asObservable()
	        .subscribe(onCompleted: { [weak self] in
	            self?.dismiss(animated: true, completion: nil)
	            _ = self?.navigationController?.popViewController(animated: true)
	        })
	        .disposed(by: bag)
	}
	```

* `skip`, `takeLast`, `filter`를 함께 사용해서 원하는 결과를 얻을 수 있는 코드를 작성했다. 하지만 좀 더 리팩토링이 가능할 것 같다. `PHPhotosLibrary.authorized`에서 다음 부분을 생각해보자.

	```swift
	authorized
		.skip(1)
		.filter { $0 == false }
	```

	* 구조 파악을 통해 여기엔 최대 2개 이상의 요소가 항상 있다는 것을 알 수 있다. 따라서 첫 번째 값을 skip하고 뒤따라 나오는 요소를 필터할 수 있다.

	```swift
	authorized
		.takeLast(1)
		.filter { $0 == false}
	```

	* 마지막 요소 이전 것은 모두 무시하고 마지막 요소가 `false`인지만 확인하는 방법도 있다.

	```swift
	authorized
		.distinctUntilChanged()
		.takeLast(1)
		.filter { $0 == false }
	```

	* `skip`과 `takeLast`를 `distinctUntilChanged()`로 대체할 수도 있다.
* 상기 코드들은 모두 같은 효과를 낸다. 따라서 구독에 대한 코드를 조금 더 줄이는 것이 가능하다. 하지만 이 것은 sequence 로직이 *절대* 변하지 않을 것임을 *확신*할 때만 가능하다. 만약 다음 iOS 버전이 출시된다면 어떻게 될까? `grant-access-alert-box` 로직이 변경되지 않는다고 확신할 수 있을까?
* 따라서 `skip`, `takeLast`, `filter` 조합을 유지하는 것이 여기서는 최선의 방법이다.   

## D. 시간 기반 필터링 연산자 사용하기

* 시간 기반 연산자에 대한 자세한 내용은 Ch.11 "Time Based Operators"에서 배울 것이다. 하지만 몇 가지 연산자들은 필터링 연산자이기도 하다.
* 시간 기반 연산자는 **Scheduler**를 사용한다. 이는 중요한 개념으로, 지금 다룰 예제에서는 `MainScheduler.instance`를 사용할 것이다.

### 1. 주어진 시간 간격 뒤에 구독 완료하기

* 사진 라이브러리의 접근은 거부하면 *접근 불가* alert이 뜨게된다. 여기서 작성할 코드는, 이러한 alert을 5초간 표시하고 그동안 사용자가 **Close** 버튼을 누르지 않은채 아무런 입력이 없다면 자동적으로 alert을 숨기고 구독을 중지하는 것이다.
* **PhotoViewController.swift**를 열고 `errorMessage()` 메소드를 확인하자. `alert(title:..., discription: ... )` 뒤에 다음과 같은 코드를 작성하자.

	```swift
	.take(5.0, scheduler: MainScheduler.instance)
	```

	* `take(_:scheduler:)`는 `take(1)`이나 `takeWhile(...)` 같은 필터링 연산자이다. `take(_:scheduler:)`는 주어진 시간동안 소스 sequence에서 나온 요소를 가지고 있는다. 주어진 시간이 지나면 결과 sequence가 완료된다.

### 2. throttle을 사용해서 부하가 많은 구독에 대한 작업 줄이기

* sequece의 현재 요소에만 관심이 있고 이전 값들은 필요없는 경우가 있다. 실제 상황에 대한 예제를 보기 위해 **MainViewController.swift**의 `viewDidLoad()`를 살펴보자.

	```swift
	images.asObservable()
	    .subscribe(onNext: { [weak self] photos in
	        guard let preview = self?.imagePreview else { return }
	        preview.image = UIImage.collage(images: photos,
	                                        size: preview.frame.size)
	    })
	    .disposed(by: bag)
	```

* 사용자가 사진을 선택할 때마다 구독은 새로운 사진 조합을 받아 콜라주를 생성한다. 새로운 사진을 받는 이상, 이전의 콜라주는 쓸모 없다. 빠르게 여러개의 사진을 성공적으로 탭했더라도 구독은 새로운 콜라주를 일일히 만들 것이다. 사실 리소스 낭비에 가깝다. 이런 상황은 현업에서 생각보다 빈번하게 일어난다.  
* `images.asObservable()` 바로 다음에 다음 코드를 삽입하자.

	```swift
	.throttle(0.5, scheduler: MainScheduler.instance)
	```

* `throttle(_:scheduler:)`는 주어진 시간 내에 뒤따라오는 요소들을 필터한다. 따라서 어떤 사용자가 사진 하나를 선택하고 바로 다음 사진을 선택하는데 0.2초가 걸렸다면 `throttle`은 첫번째 요소를 필터하고 두번째 사진만 내뱉을 것이다. 이렇게하면 첫 번째 중간 콜라주를 작성하는 시간이 절약된다.
* 당연히 `throttle`는 한가지 이상의 요소들과 함께 작업할 수 있다. 만약 사용자가 5개의 사진을 선택간격 0.5초 이내로 빠르게 탭하였다면, `throttle`은 첫 4개를 필터하고 5번째 요소만 내뱉을 것이다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/12.%20throttle.png?raw=true" height = 200>

* `throttle`을 사용할 수 있는 상황은 다음과 같다.
	* 현재의 텍스트를 서버 API에 보내는 검색 텍스트 필드를 구독할 때, 사용자가 빠르게 타이핑 한다는 가정이 있다면 타이핑을 완전히 마쳤을 때의 텍스트를 서버에 보내도록 `throttole`을 이용할 수 있다.
	* 사용자가 bar 버튼을 눌러 view controller를 present modal 할 때, present modal이 여러번 되지 않도록 더블/트리플 탭을 방지할 수 있다.
	* 사용자가 손가락을 이용해 화면을 드래그할 때, 드래그가 끝나는 지점에만 관심이 있을 수 있다. 드래그 중일 때의 터치 위치는 무시하고 터치 위치가 변경을 멈추었을 때의 요소만 고려할 수 있다.
* `throttle(_:scheduler:)`는 너무 많은 입력값을 받고 있을 때 아주 유용하게 쓸 수 있다.

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
