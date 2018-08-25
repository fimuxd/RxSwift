# Ch.4 Observables and Subjuects in Practice

## A. ViewController에서 Variable 이용하기

* 다음 코드를 **MainViewController.swift**의 `MainViewController` 내에 입력합니다.

	```swift
	private let bag = DisposeBag()
	private let images = Variable<[UIImage]>([])
	```
	* 다른 클래스끼리 통신하지 않는다면 `private`로 정의할 것

* 뷰컨이 모든 observable을 dispose 할 때부터, dispose bag은 뷰컨이 소유한다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/04_ObservablesAndSubjectsInPractice/1.memoryControl.png?raw=true" height = 250>

	* 위 그림은, Rx가 메모리 관리를 얼마나 쉽게 하는지 보여주고 있다.
	* 그냥 `bag`에 구독을 던져놓으면, viewController가 할당 해제 될 때 폐기된다.
	* 단, rootVC 같은 특정 뷰컨에서는 이런 작용이 일어나지 않는다. rootVC은 앱이 종료되기 전까진 해제되지 않기 때문.

* `actionAdd()`에 다음 코드를 입력하세요

	```swift
	images.value.append(UIImage(named: "IMG_1907.jpg")!)
	```

	* 일반적인 variable과 마찬가지로 `images`의 현재값을 변경한 것
	* `Variable` 클래스는 자동적으로 자신의 `value` 프로퍼티에 부여한 값들에 대해 각각의 observable 시퀀스를 생성해낸다.
	* `images Variable`의 초기값은 빈 array 고, 유저가 `+` 버튼을 누를 때마다 `images`를 통해 만들어진 observable 시퀀스가 새로운 어레이를 `.next` 이벤트로 방출한다.
* 유저가 현재 선택을 취소할 수 있도록, `actionClear():`에 하기 코드를 추가한다.

	```swift
	images.value = []
	```

## B. 콜라주에 사진 추가하기

* 이제 `image`가 연결되었으므로 변경사항을 관찰할 수 있고, 이에 따라서 콜라주 미리보기를 업데이트 할 수 있다.
* `viewDidLoad()`에서, 다음과 같이 `images`에 대해 구독을 추가한다.
* `images`는 varaible이므로 구독을 위해서 `asObservable()` 해야함을 잊지 말자.

	```swift
	    images.asObservable()
	        .subscribe(onNext: { [weak self] photos in
	            guard let preview = self?.imagePreview else { return }
	            preview.image = UIImage.collage(images: photos, size: preview.frame.size)
	            })
	        .disposed(by: bag)
	```
	* `images`가 방출하는 `.next`이벤트를 구독할 수 있고, 이러한 이벤트를 `UIImage.collage(image:size:)` 함수를 거쳐 콜라주를 만들 수 있다.
	* 이 구독을 뷰컨의 dispose bag에 추가한다.
* 이 chapter에서, `viewDidLoad()`의 observable에 대해서 구독을 할 것이지만, 추후에는 다른 클래스와 MVVM 아키텍처에서도 할 수 있다.
* 이제 UI 콜라주가 생겼으니, 유저는 `images`를 `+`버튼을 탭하여 업데이트 하거나 클리어 할 수 있다.


## C. 복잡한 View Controller UI 구동하기

* UI는 다음과 같은 방법으로 UX를 개선할 수 있다.
	* 만약 아직 아무 사진도 추가하지 않았거나, `Clear`버튼을 누른 직후라면, `Clear`이 작동하지 않게 할 수 있다.
	* 같은 상황에서 `Save` 버튼 역시 필요없다.
	* 빈 공간을 남기고 싶지 않다면, 홀수 개의 사진이 추가되었을 때 `Save` 버튼이 작동하지 않게 할 수 있다.
	* 사진을 6개까지만 추가하도록 제한할 수 있다.
	* ViewController가 현재 선택 개수를 보여줄 수 있다.
* 이걸 Reactive 하지 않은 기존의 방식으로 하려면 얼마나 긴 코드를 작성해야 할까요? 하지만 Rx에서는 매우 간단합니다.
* `viewDidLoad():`내에 아래 코드를 추가한다.

	```swift
	    images.asObservable()
	        .subscribe(onNext: { [weak self] photos in
	            self?.updateUI(photos: photos)
	        })
	        .disposed(by: bag)
	```

* 	`.updateUI(photos:)` 함수가 없으니 아래 함수를 입력한다.

	``` swift
	    private func updateUI(photos: [UIImage]) {
	        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
	        buttonClear.isEnabled = photos.count > 0
	        itemAdd.isEnabled = photos.count < 6
	        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
	    }
	```

	* 이 코드는 위에서 나열한 모든 개선을 반영한다. (헐..😳)
	* 각각의 로직은 한줄로 표현되어있으며 이해하기 쉽다.
* 지금부터 Rx가 iOS 앱에 적용되었을 때 진짜 어떤점이 좋은지 알 수 있다.

## D. Subject를 통해 다른 View Controller와 통신하기

* 여기서 할일은 유저가 카메라롤에 있는 임의의 사진을 선택할 수 있도록 `MainViewController`와 `PhotosViewController`를 연결하는 것이다.
* `PhotosViewController`로 push 하기 위해, **MainViewController.swift** 내의 `actionAdd()`에 하단의 코드를 추가한다. 기존에 입력했던 `IMG_1907.jpg` 만을 사용하게 하는 코드는 주석처리 한다.

	```swift
	  let photosViewController = storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController

	    navigationController?.pushViewController(photosViewController, animated: true)
	```

	* 이렇게 하고 앱을 실행해보면 (카메라롤 접근허용 창이 뜨고) `photosViewController`로 잘 넘어가는 것을 알 수 있다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/04_ObservablesAndSubjectsInPractice/2.delegate.png?raw=true" height = 250 >

	* 기존의 Cocoa 프레임워크를 다음에 해야할 일은 `photosViewController`의 사진들을 `mainViewController`로 서로 통신하기 위해 delegate 프로토콜을 쓰는 것일 것이다. 하지만 이건 매우 Rx 답지아나!
	* RxSwift에서는 (이런 ~그지같은~ 방법이 아닌) 두개의 **어떠한** 클래스라도 연결할 수 있는 아주 universal 한 방법이 있다. 바로 `Observable`이다! 어떠한 프로토콜도 정의할 필요없다. 왜냐하면 `Observable`은 어떤 종류의 메시지라도 자신을 구독하는 Observer에게 전달할 수 있기 때문이다.

### 1. 선택한 사진에서 Observable 만들기

* 유저가 카메라롤에 있는 사진을 탭할 때마다 `.next` 이벤트를 방출하는 subject를 `PhotosViewController`에 만들 것이다.
* **PhotosViewController.swift**내에 `import RxSwift`를 하자.
* 지금 하고 싶은 것은 선택한 사진을 추출하기 위해 `PublishSubject`를 추가하는 것이다. 하지만, public하게 접근 허용하긴 싫다. 다른 클래스에서 `onNext(_)`를 호출하여 이 subject가 값을 방출하도록 하면 안되니까. (최소한 이 예제에선)
* 하단의 코드를 `PhotosViewController`에 추가한다.

	```Swift
	private let selectedPhotosSubject = PublishSubject<UIImage>()
	    var selectedPhotos:Observable<UIImage> {
	        return selectedPhotosSubject.asObservable()
	    }
	```

	* 선택된 사진을 방출할 private한 `PublishSubject`와 subject의 observable을 방출할 `selcectedPhotos` 프로퍼티를 만들었다.
	* 이 프로퍼티를 구독하는 것이 `MainViewController`에서 다른 간섭/변경 없이 사진 sequence를 관찰하는 방법이다.  
* `PhotosViewController`는 이미 카메라롤에서 사진을 읽고 그것을 콜렉션뷰로 보여주는 코드를 포함하고 있다.
* 따라서 유저가 콜렉션뷰의 셀(사진)을 탭할 때마다 그 사진들을 방출하는 코드를 작성하는 것이 여기서 해야할 전부.
* `collectionView(_:didSelectItemAt:)`를 확인해보자. 이 코드는 선택한 이미지를 가져와서 콜렉션셀을 깜박여서 탭했음을 확인할 수 있는 시각적 피드백을 주는 것이다.
* `imageManager.requestImage(...)`은 해당 클로저가 잘 작동할 때 선택한 사진의 `image`와 `info` 파라미터를 줄 수 있도록 하는 것이다. 여기서 `selectedPhotosSubject`를 통해 `.next`이벤트를 방출하는 것이 해야할 일이다.
* 해당 클로저 내의 `guard`문 하단에 다음과 같은 코드를 추가한다.

	```swift
	if let isThumbnail = info[PHImageResultIsDegradedKey as NSString] as? Bool, !isThumbnail {
	            self?.selectedPhotosSubject.onNext(image)
	        }
	```

	* `info` dictionary를 통해 이미지가 썸네일인지 원본이미지인지 확인할 수 있다.
	* `imageManager.requestImage(...)`는 해당 클로저를 각각의 사이즈에 대해 한번씩 호출할 것이다.
	* 원본이미지를 받았을 때는 원본 이미지를 제공할 수 있도록 `onNext(_)`이벤트를 subject를 통해 방출한다.

* 프로토콜을 제거하면, 두 controller의 관계는 다음과 같이 아주 간단해진다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/04_ObservablesAndSubjectsInPractice/3.simple.png?raw=true" height = 250>


### 2. 선택한 사진들에 대한 Sequence 관찰하기

* 다음으로 해야할 일은 **MainViewController.swift**로 돌아가서 *선택한 사진들에 대한 Sequence 관찰*을 할 수 있는 코드를 작성하는 것이다.
* `actionAdd()`내 navigation 관련 동작을 구현한 코드 다음에 다음과 같은 코드를 작성한다.

	```swift
	photosViewController.selectedPhotos
	            .subscribe(onNext: { [weak self] newImage in
	                guard let images = self?.images else { return }
	                images.value.append(newImage)
	                }, onDisposed: {
	                    print("completed photo selection")
	            })
	            .disposed(by: bag)
	```

### 3. Disposing subscriptions - review

* 여기까지보고 앱을 구동해보면 아주 잘 작동하는 것처럼 보이지만 한가지 간과한 것이 있다.
* 상기 코드를 보면 분명히 disposed 되었을 때 `"completed photo selection"` 메시지가 콘솔에 프린트되도록 해놓았다. 하지만 콘솔을 확인해보면 해당 메시지는 보이지 않는다. 이건 아직 해당 subject가 dispose 되지 않았다는 뜻이다.
* 당연하다. 왜냐하면 dispose bag 을 통해 dispose 되도록 명령해놓았고, `MainViewController`가 완전히 할당 해제 되어야만 dispose bag이 dispose 시킬 것이기 때문이다. 이 것이 싫다면 `.complated` 또는 `.error` 이벤트를 방출하므로써 완전 종료될 수 있을 것이다.
* 따라서, `PhotosViewController`가 사라질 때, 해당 이벤트를 방출하도록 하면 될 것이다. 아래의 코드를 `PhotosViewController`의 `viewWillDisappear(_:)` 에 추가한다.

	```swift
	selectedPhotosSubject.onCompleted()
	```

	* 이렇게 하면 `PhotosViewController`가 사라질 때마다 해당 subject가 dispose 되는 것을 확인할 수 있다.

## E. 커스텀한 Observable 만들기

* 기존의 Apple API를 이용하면, `PHPhotoLibrary`에 대한 extension을 추가할 수 있을 것이다.
* 하지만 여기선 `PhotoWriter`라는 명칭의, 완전히 새로운 커스텀 클래스를 만들 것이다.
* 사진 저장을 쉽게 해줄 수 있는 `Observable`을 만들 것이다.
	* 이미지가 디스크에 성공적으로 읽혀졌다면 해당 이미지의 assetID를 방출하거나 `.completed` 또는 `.error` 이벤트를 방출할 수도 있을 것이다.

### 기존의 API 래핑하기

* **PhotoWriter.swift**를 열고 `import RxSwift` 한다.
* 다음의 코드를 작성한다.

	```swift
	// 1
	    static func save(_ image: UIImage) -> Observable<String> {
	        return Observable.create({ observer in

	            // 2
	            var savedAssetId: String?
	            PHPhotoLibrary.shared().performChanges({

	                // 3
	                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
	                savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
	            }, completionHandler: { success, error in

	                // 4
	                DispatchQueue.main.async {
	                    if success, let id = savedAssetId {
	                        observer.onNext(id)
	                        observer.onCompleted()
	                    } else {
	                        observer.onError(error ?? Errors.couldNotSavePhoto)
	                    }
	                }
	            })

	            // 5
	            return Disposables.create()
	        })
	    }
	```

	* 주석을 따라 하나씩 살펴보자
		* 1) `save(_:)` 함수를 만든다. 해당 함수는 `Observable<String>`을 리턴할 것이다. 왜냐하면 사진을 저장한 다음에는 생성된 하나의 요소를 방출할 것이기 때문이다.
			* `Observable.create(_)`는 새로운 `Observable`을 생성할 것이기 때문에 어떤 Observable을 생성할 것인지를 이 클로저 내부에서 구현해야 한다.
		* 2) `performChanges(_:completionHandler:)`의 첫 번째 클로저 파라미터에서 제공된 이미지를 통해 콜라주된 사진을 생성할 것이다. 그리고 두 번째 클로저 파라미터에서 assetID 또는 `.error` 이벤트를 방출하게 될 것이다.
		* 3) `PHAssetChangeRequest.creationRequestForAsset(from:)`을 통해 새로운 사진세트를 만들 수 있고 이건 `savedAssetId`에 있는 해당 id로 저장할 것이다.
		* 4) 만약 성공 리스폰스를 받고 `savedAssetId`가 유효한 assetID 라면 `.next`와 `.completed` 이벤트를 방출할 것이다. 그렇지 않다면 `.error` 이벤트를 통해 에러를 방출할 것이다.
		* 5) `Disposible`이 리턴되도록 한다. (`.create`)의 리턴 값
* 왜 `.next`이벤트만 방출하는 `Observable`이 필요할까? 의문이 들 수 있다. 당연히 그렇지 않다. 다른 연산자들도 사용가능하다. 에를 들면,
	* `Observable.never()`: 어떤 요소도 방출하지 않는 Observable sequence
	* `Observable.just(_:)`: `.completed` 이벤트와 하나의 요소만 방출.
	* `Observable.empty()`: `.completed` 이벤트만 방출.
	* `Observable.error(_)`: 하나의 `.error` 이벤트만 방출
* 그럼 추가로 궁금하다. 그럼 내가 배운 [Single](https://github.com/fimuxd/RxSwift/blob/master/Lectures/02_Observables/Ch2.%20Observables.md#h-traits-사용)은 뭐여?

## F. RxSwift trait 연습하기

### 1. Single

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/04_ObservablesAndSubjectsInPractice/4.%20single.png?raw=true" height = 100>

* Single은 `.success(Value)` 이벤트 또는 `.error` 이벤트를 한번만 방출한다.
* `success` = `.next` + `.completed`
* 파일 저장, 파일 다운로드, 디스크에서 데이터 로딩 같이, 기본적으로 값을 산출하는 비동기적 모든 연산에도 유용하다.

#### 사용 예시
* `PhotoWriter.save(_)`에서 처럼, 정확히 한가지 요소만을 방출하는 연산자를 래핑할 때
	* `Observable` 대신 `Single`을 생성하여 `PhotoWriter`의 `save(_)` 메소드를 업데이트 할 수 있다.
* signle sequence가 둘 이상의 요소를 방출하는지 구독을 통해 확인하면 error가 방출될 수 있다.
	* 이 것은 아무 Observable에 `asSingle()`를 붙여 `Single`로 변환시켜서 확인할 수 있다.

### 2. Maybe

* `Maybe`는 `Single`과 비슷하지만 유일하게 다른 점은 성공적으로 complete 되더라도 아무런 값을 방출하지 않을 수도 있다는 것이다.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/04_ObservablesAndSubjectsInPractice/5.%20maybe.png?raw=true" height = 100>

* 사진을 가지고 있는 커스텀한 포토앨범앱이 있다. 그리고 그 앨범명은 UserDefaults에 저장될 것이고 해당 ID는 앨범을 열고 사진을 저장할 때마다 남을 것이다. 
* 이 때 `open(albumId:) -> Maybe<String>` 메소드를 통해 다음과 같은 상황을 관리할 수 있다.
	* 주어진 ID가 여전히 존재하는 경우, `.completed` 이벤트를 방출한다.
	* 유저가 앨범을 삭제하거나, 새로운 앨범을 생성하는 경우 `.next` 이벤트롤 새로운 ID 값과 함께 방출시킨다. 이렇게함으로써 UserDefaults가 해당 값을 보존할 수 있도록.
	* 뭔가 잘못 되었거나 사진 라이브러리에 엑세스할 수 없는 경우, `.error` 이벤트를 방출한다.
* `asSingle`처럼, 어떤 Observable을 `Maybe`로 바꾸고 싶다면, `asMaybe()`를 쓸 수 있다.

### 3. Completable

* `Completable`은 `.completed` 또는 `.error(Error)`만을 방출한다.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/04_ObservablesAndSubjectsInPractice/6.%20completable.png?raw=true" height = 100>

* 하나 기억해야 할 것은, observable을 completable로 바꿀 수 없다는 것이다.
* observable이 값요소를 방출한 이상, 이 것을 completable로 바꿀 수는 없다.
* completable sequence를 생성하고 싶으면 `Completable.create({...})`을 통해 생성하는 수 밖에 없다. 이 코드는 다른 observable을 `create`를 이용하여 생성한 방식이랑 매우 유사하다.
* `Completeble`은 어떠한 값도 방출하지 않는다는 것을 기억해야 한다. 솔직히 이런게 왜 필요한가 싶을 것이다.
	* 하지만, 동기식 연산의 성공여부를 확인할 때 `completeble`은 아주 많이 쓰인다.
* 작업했던 `Combinestagram` 예제를 통해 생각해보자.
	* 유저가 작업할 동안 자동저장되는 기능을 만들고 싶다.
	* background queue에서 비동기적으로 작업한 다음에, 완료가되면 작은 노티를 띄우거나 저장 중 오류가 생기면  alert을 띄우고 싶다.
* 저장 로직을 `saveDocumet() -> Completable` 에 래핑했다고 가정해보자. 다음과 같이 표현할 수 있다.

	```swift
	saveDocument()
		.andThen(Observable.from(createMessage))
		.subscribe(onNext: { message in
			message.display()
		}, onError: { e in
			alert(e.localizedDescription)
		})
	```

	* `andThen` 연산자는 성공 이벤트에 대해 더 많은 completables이나 observables를 연결하고 최종 결과를 구독할 수 있게 합니다.

## G. 커스텀한 Observable 구독하기

* `PhotoWriter.save(_)` observable은 새로운 asset ID를 한번만 방출하거나 에러를 방출한다. 따라서 이건 아주 좋은 `Single` 케이스가 될 수 있다.
* **MainViewController.swift**를 열고 `actionSave()`에 아래의 코드를 추가한다. 이 것은 Save 버튼을 눌렀을 때 실행될 액션에 대한 것이다.

	```swift
	guard let image = imagePreview.image else { return }

	        PhotoWriter.save(image)
	            .asSingle()
	            .subscribe(onSuccess: { [weak self] id in
	                self?.showMessage("Saved with id: \(id)")
	                self?.actionClear()
	                } , onError: { [weak self] error in
	                    self?.showMessage("Error", description: error.localizedDescription)
	            })
	            .disposed(by: bag)
	```

	* 상기 코드는 현재 콜라주를 저장하기 위해 `PhotoWriter.save(image)`를 호출한 것이다.
	* 그런 다음에 구독이 하나의 요소를 받을 때, 리턴된 `Observable`을 `Single`로 전환한다.
	* 이 후 해당 메시지가 성공인지 에러인지를 표시한다.
	* 추가적으로, 만약 이미지가 성공적으로 저장되면 콜라주 화면을 클리어한다.

## F. Challenges

### Challenge 1: Single 이용해보기

* 카메라롤에 사진을 저장하는 용도로 `.asSingle()`을 사용하는 것을 인지하지 못했을 것이다.
* observable sequence는 이미 최대 하나의 요소만을 방출한다.
* **PhotoWriter.swift**의 `save(_)`의 리턴타입을 Single<String>으로 바꾼다. 그리고 `Observable.create`를 `Single.create`로 바꾼다.
* 여기서 하나 신경써야할 것이 있다. `Single.create`은 observer가 아닌 클로저를 파라미터로 받는다는 것이다.
	*  `Observable.create`는 observer를 파라미터로 받는다. 따라서 여러개의 값을 방출하고 이벤트를 종료할 수 있다.
	*  `Single.create`는 `.success(T)` 또는 `.error(E)` 값을 출력할 수 있는 클로저를 파라미터로 받는다.
	*  따라서 이 문제에서는 `single(.success(id))` 와 같은 방식으로 호출할 수 있다.

> A.
>
> ```swift
> static func save(_ image: UIImage) -> Single<String> {  //1. 리턴 타입을 Single<String>로 바꿈
>         return Single.create(subscribe: { observer in       //2. Single.create로 바꿈
>             var savedAssetId: String?
>             PHPhotoLibrary.shared().performChanges({
>                 let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
>                 savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
>             }, completionHandler: { success, error in
>                 DispatchQueue.main.async {
>                     if success, let id = savedAssetId {
>                         observer(.success(id))              //3. Single이 뱉을 수 있는 .success()로 값을 방출
>                     } else {
>                         observer(.error(error ?? Errors.couldNotSavePhoto))
>                     }
>                 }
>             })
>             return Disposables.create()
>         })
>     }
> ```

### Challenge 2: 현재 alert에 커스텀한 observable 추가하기

* **MainViewController.swift** 에서 `showMessage(_:description:)` 메소드를 확인해보자.
* 이 메소드는 유저가 alert 화면을 끄기 위해 **Close** 버튼을 누르면 실행될 것이다. 이미 앞선 예제를 통해 `PHPhotoLibrary.performChanges(_)`를 구현했던 것과 비슷해보인다.
* 다음과 같이 진행해보자.
	* `UIViewController`에 extension을 추가하여 화면에 제목과 메시지를 포함한 alert을 띄우고 Completable을 리턴하는 메소드를 작성해보자.
	* 구독이 종료되었을 때 alert도 종료시켜야 한다
* 마지막에는 새로운 completable을 이용하여 `showMessage(_:description:)` 내에서 alert을 띄울 수 있도록 한다.

> A.
>
> 1. 다음과 같이 UIViewController extension을 작성하여 메소드 작성
>
> ```swift
> import UIKit
> import RxSwift
>
> extension UIViewController {
>     func alert(title: String, text: String?) -> Completable {
>         return Completable.create(subscribe: { [weak self] completable in
>             let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
>             let closeAction = UIAlertAction(title: "Close", style: .default, handler: { _ in
>                 completable(.completed)
>             })
>             alertVC.addAction(closeAction)
>             self?.present(alertVC, animated: true, completion: nil)
>             return Disposables.create {
>                 self?.dismiss(animated: true, completion: nil)
>             }
>         })
>     }
> }
> ```
>
> 2. MainViewController.swift의 showMessage(_:description:)에 구현할 것
>
> ```swift
>         alert(title: title, text: description)
>             .subscribe()
>             .disposed(by: bag)
> ```

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
