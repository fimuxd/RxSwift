# Ch.1 Hello RxSwift

## A. RxSwift?

> RxSwift is a library for composing asynchronous and event-based code by using observable sequences and functional style operators, allowing for parameterized execution via schedulers.

*By Marin Todorov. ‘RxSwift - Reactive Programming with Swift.’ iBooks.*

~무슨 말인지 잘 모르겠지만,~ 주목할만한 keywords: `observable(관찰가능한)`, `asynchronous(비동기)`, `functional(함수의)`, `via schedulers(스케줄러를 통해)`)

다시 표현하자면 이렇다고 한다.

> **RxSwift는 '본질적'으로 코드가 '새로운 데이터에 반응'하고 '순차적으로 분리 된' 방식으로 처리함으로써 '비동기식' 프로그램 개발을 간소화합니다.**

## B. Cocoa and UIKit Asynchronous APIs

Apple은 iOS SDK 내에서 비동기식 코드를 작성할 수 있도록 다양한 API를 제공하고 있다. 주된 방법은 다음과 같다.

* Notification Center
* The delegate pattern
* Grand Central Dispatch(GCD)
* Closures

일반적으로 대부분의 클래스들은 비동기적으로 작업을 수행하고 모든 UI 구성요소들은 본질적으로 비동기적이다. 따라서 내가 어떤 앱 코드를 작성했을 때 정확히 매번 어떤 순서로 작동하는지 가정하는 것을 불가능하다. 결국 앱의 코드는 사용자 입력, 네트워크 활동 또는 기타 OS 이벤트와 같은 다양한 외부 요인에 따라 완전히 다른 순서로 실행될 수 있다. 

> 결국 문제는, Apple의 SDK내의 API를 통한 복합적인 비동기 코드는 부분별로 나눠서 쓰기 매우 어려울 수 밖에(또는 거의 추적불가능) 없다는 것 
 
 
## C. 비동기 프로그래밍 용어들
### 1. State, and specifically, shared mutable state

state(아마도 번역하자면 상태? 정도겠죠)는 정의하기 어려운 개념이니 예를 들어 이해해보도록 합니다.

* 처음 시동한 Laptop은 ~불량이 아닌 이상~ 잘 작동함
* 하지만 시간이 지날 수록 반응이 느려지거나 반응을 멈추는 상황이 발생함. 왜 그럴까?
* Hardware와 Software는 그대로이지만 변한 것은 State
* Laptop을 재시동하거나 사용할 수록 메모리상의 데이터, 디스크에 저장된 내용을 포함한 온갖 찌꺼기?파일들은 laptop에 남게 됨. 이 것이 laptop의 state(상태)라고 할 수 있음. 
* 쉽게 얘기하면 사용하면 사용할 수록 데이터의 교환 등등이 이루어지고 또 남는 것들이 생기면서 상태가 변화한다는 뜻

> 앱의 State(상태)를 관리하는 것(특히 여러가지 비동기 구성요소를 공유할 때)은 RxSwift를 통해 배울 수 있는 중요한 포인트 중 하나

### 2. 명령형 프로그래밍

명령형 프로그래밍이란 선언형 프로그래밍과 반대되는 개념으로, 프로그래밍의 상태와 상태를 변경시키는 구문의 관점에서 연산을 설명하는 프로그래밍 패러다임의 일종이다. *출처: [위키](https://ko.wikipedia.org/wiki/명령형_프로그래밍)*

* 명령형 프로그래밍은 강아지와 노는 것과 비슷하다. (물어와! 앉아! 빵!)
* 앱에게 정확히 **'언제' '무엇을'** 하라고 말하고 싶을 때 명령형 코드를 쓸 수 있다. (wow!)
* 컴퓨터가 이해하고 있는 방식과도 비슷하다. 예를 들어서 모든 CPU는 간단한 명령어으로 이루어진 긴 sequences를 따른다. 
* 문제는 인간이 복잡하고 비동기적인 앱을 만들기 위해 명령형 코드를 사용하는 것이 너무나 어렵다는 점!
* 예를 들어 iOS ViewController의 `viewDidAppear(_:)`를 확인해 봅시다.

	```swift
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		setupUI()
		connectUIControls()
		createDataSource()
		listenForChanges()
	}
	```
	* 이렇게만 봐서는 각각의 method 들이 무슨 동작을 하는지 전혀 알 수 없다.
	* viewController 자체의 property를 업데이트 하는지, 그렇지 않은지도 알 수 없다.
	* 각각의 method가 순서대로 잘 실행될지도 보증할 수 없다.
	* 누군가 실수로 method의 순서를 바꿨다면 이로 인해 앱이 다르게 작동되어 버릴 수도 있다.

### 3. 부(수)작용들

* 부수작용이란 현재 scope 외 상태에서 일어나는 모든 변화를 뜻한다
* 예를 들어 상기 코드에서 `connectUIControls` 라는 method는 아마 어떤 UI 구성요소를 제어하기 위한 `event handler` 일 것이다. 이 것이 view의 state(상태)를 변경하게 된다면 부수작용을 만들게 된다.
* 스크린 상 `label`의 `text`를 추가하거나 변경한다는 것 > 디스크에 저장된 데이터를 수정한다는 것 > 부수작용 발생한다는 것
* 부수작용은 그 자체로 나쁜 것이 아니다. 문제는 컨트롤이 가능하냐는 것
* 각각의 코드에 대해서, 해당 코드가 어떤 부수작용을 발생시킬 수 있는 코드인지, 단순 과정을 나열한 것인지, 명확한 결과값만을 발생시키는 것인지 정확히 인지하고 있는 것이 중요하다.

> RxSwift는 이러한 이슈를 추적가능하게 해준다.

### 4. 선언형 코드

* 명령형 프로그래밍에서의 상태 변화는 자유자재로 가능하다.
* 함수형 코드에서는 부수작용을 일으킬 수 없다.
* RxSwift는 이 두 가지를 아주 잘 결합하여 동작하게 한다. 
	* 명령형 프로그래밍 + 함수형 프로그래밍 
	* **자유로운 상태변화 + 추적/예측가능한 결과값** (wow)
* 선언형 코드(명령형과 반대)를 통해 동작을 정의할 수 있으며, RxSwift는 관련 이벤트가 있을 때 마다 이러한 동작을 실행하고 작업할 수 있는 불변의 고유한 데이터 입력을 제공한다.
* 이렇게 하면 변경 불가능한 데이터로 작업하고, 순차적이고 결과론적인 방식으로 코드를 실행할 수 있다.

### 5. Reactive systems

`반응형 시스템` 이란 의미는 상당히 추상적이며, 다음과 같은 특성의 대부분 또는 전부를 나타내는 iOS 앱을 다루게 된다.

* 반응 (Responsive): 항상 UI를 최신 상태로 유지하며, 가장 최근의 앱 상태를 표시함
* 복원력 (Resilient): 각각의 행동들은 독립적으로 정의되며, 에러 복구를 위해 유연하게 제공됨
* 탄력성 (Elastic): 코드는 다양한 작업 부하를 처리하며, 종종 lazy full 기반 데이터 수집, 이벤트 제한 및 리소스 공유와 같은 기능을 구현
* 메시지 전달(Message driven): 구성요소는 메시지 기반 통신을 사용하여 재사용 및 고유한 기능을 개선하고, 라이프 사이클과 클래스 구현을 분리함

## D. RxSwift 기초

* Microsoft에서부터 Reactive의 역사는 과감히 스킵한다. 자세한 내용은 [여기서](http://reactivex.io)
* Rx code의 세 가지 building block(구성요소); observables(생산자), operators(연산자), schedulers(스케줄러)에 대해 알아보자

### 1. Observables
* `Observable<T>` 클래스는 Rx 코드의 기반
*  `T` 형태의 데이터 snapshot을 '전달' 할 수 있는 일련의 이벤트를 비동기적으로 생성하는 기능
*  다시 말하면, 다른 클래스에서 만든 값을 시간에 따라 읽을 수 있다.
*  하나 이상의 observers(관찰자)가 실시간으로 어떤 이벤트에 반응하고 앱 UI를 업데이트 하거나 생성하는지를 처리하고 활용할 수 있게 한다.
*  ObservableType 프로토콜(`Observable<T>`가 준수함)은 매우 간단하다. 다음 세 가지 유형의 이벤트만 `Observable`은 방출하며 따라서 observers(관찰자)는 이들 유형만 수신할 수 있다.
	* `next`: 최신/다음 데이터를 '전달'하는 이벤트
	* `completed`: 성공적으로 일련의 이벤트들을 종료시키는 이벤트. 즉, `Observable`(생산자)가 성공적으로 자신의 생명주기를 완료했으며, 추가적으로 이벤트를 생성하지 않을 것임을 의미
	* `error`: `Observable`이 에러를 발생하였으며, 추가적으로 이벤트를 생성하지 않을 것임을 의미 (에러와 함께 완전종료)
* 아래 그림과 같이 시간에 걸쳐서 발생하는 비동기 이벤트를 생각해보자.
	
	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/01_HelloRxSwift/1.%20observableT.png?raw=true" height = 150>
	
	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/01_HelloRxSwift/2.%20observableT.png?raw=true" height = 200>
	
	* 상기 세 가지 유형의 Observable 이벤트는, `Observable` 또는 `Observer`의 본질에 대한 어떤 가정도 하지 않는다. 
	* 따라서 델리게이트 프로토콜을 사용하거나, 클래스 통신을 위해 클로저를 삽입할 필요가 없다. 
* 실상황에서 아이디어를 얻으려면 다음과 같은 두 가지의 Observable sequence(유한/무한)를 이해해야 한다. 

#### Finite observable sequences

* 어떤 Observable sequence는 0, 1 또는 다른 값을 방출한 뒤, 성공적으로 또는 에러를 통해 종료된다.
* iOS 앱에서, 인터넷을 통해 파일을 다운로드 하는 코드를 생각해보자.
	* i) 다운로드를 시작하고, 들어오는 데이터를 관찰한다.
	* ii) 계속해서 파일 데이터를 받는다.
	* iii) 네트워크 연결이 끊어진다면, 다운로드는 멈출 것이고 연결은 에러와 함께 일시정지 될 것이다.
	* iv) 또는, 성공적으로 모든 파일 데이터를 다운로드 할 수 있을 것이다.
	* 이러한 흐름은 앞에서 서술한 Observable의 생명 주기와 정확히 일치한다. RxSwift 코드로 표현하면 다음과 같다.

	```swift
	API.download(file: "http://www...")
		.subscribe(onNext: { data in
			... append data to temporary file
		},
		onError: { error in 
			... display error to user
		},
		onCompleted: {
			... use downloaded file
		})
	```
	
	* `API.download(file:)`은 네트워크를 통해 들어오는 `Data`값을 방출하는 `Observable<Data>` 인스턴스를 리턴할 것이다. 
	* `onNext` 클로저를 통해 `next` 이벤트를 받을 수 있다. 예제에서는 받은 데이터를 디스크의 `temporary file`에 저장하게 될 것이다.
	* `onError` 클로저를 통해 `error` 이벤트를 받을 수 있다. alert 메시지 같은 action을 취할 수 있을 것이다.
	* 최종적으로 `onCompleted` 클로저를 통해 `completed` 이벤트를 받을 수 있으며, 이를 통해 새로운 viewController를 push하여 다운로드 받은 파일을 표시하는 등의 엑션을 취할 수 있을 것이다.

#### Infinite observable sequences

* 자연적으로 또는 강제적으로 종료되어야 하는 파일 다운로드 같은 활동과 달리, 단순히 무한한 sequence가 있다. 보통 UI 이벤트는 무한하게 관찰가능한 sequence이다.
* 예를 들어, 기기의 가로/세로 모드에 따라 반응해야하는 코드를 생각해보자.
	* i) `UIDeviceOrientationDidChange` observer를 추가한다. 
	* ii) 방향 전환을 관리할 수 있는 callback method를 제공해야 한다. `UIDevice`의 현재 방향값을 확인 한 뒤, 이 값에 따라 화면이 표시될 수 있도록 해야한다.
	* 방향전환이 가능한 디바이스가 존재하는 한, 이러한 연속적인 방향 전환은 자연스럽게 끝날 수 없다.
	* 결국 이러한 시퀀스는 사실상 무한하기 때문에, 항상 최초값을 가지고 있어야 한다.
	* 사용자가 디바이스를 절대 회전하지 않는다고 해서 이벤트가 종료된 것도 아니다. 단지 이벤트가 발생한 적이 없을 뿐.
	* RxSwift 코드로 표현하면 다음과 같다.
	
	```swift
	UIDevice.rx.orientation
		.subscribe(onNext: { current in
			switch current {
				case .landscape:
					... re-arrange UI for landscape
				case .portrait:
					... re-arrange UI for portrait
			}
		})
	```
	
	* `UIDevice.rx.orientation`은 `Observable<Orientation>`을 통해 만든 가상의 코드임.
		* 아주 쉬운 코드로, 어떻게 만들 수 있는지는 다음 Chapter에서 배운다고 합니다.
	* 이를 통해 현재 `Orientation`(방향)을 받을 수 있고, 받은 값을 앱의 UI에 업데이트 할 수 있다.
	* 해당 Observable에서는 절대 발생하지 않을 이벤트이기 때문에 `onError`나 `onCompleted` parameter는 건너뛸 수 있다. 

### 2. Operators

* `observableType`과 `Observable` 클래스의 구현은 보다 복잡한 논리를 구현하기 위해 함께 구성되는 비동기 작업을 추상화하는 많은 메소드가 포함되어 있음. (휴 뭔말인지 ^^) 이러한 메소드는 매우 독립적이고 구성가능하므로 보편적으로 Operators(연산자) 라고 불림.
* 이러한 Operator(연산자) 들은 주로 비동기 입력을 받아 부수작용 없이 출력만 생성하므로 퍼즐 조각과 같이 쉽게 결합할 수 있다.
* 예를 들어 `(5 + 6) * 10 - 2`	라는 수식을 생각해보자
	* `*`, `()`, `+`, `-` 같은 연산자를 통해 데이터에 적용하고 결과를 가져와서 해결될 때까지 표현식을 계속 처리하게 된다. 
	* 비슷한 방식으로 표현식이 최종값으로 도출 될 때까지, `Observable`이 방출한 값에 Rx 연산자를 적용하여 부수작용을 만들 수 있다.
* 다음은 앞서 방향전환에 대한 예제에 Rx 연산자를 적용시킨 코드이다.

	```swift
	UIDevice.rx.orientation
		.filter { value in
			return value != .landscape
		}
		.map { _ in
			return "Portait is the best!"
		}
		.subscribe(onNext: { string in
			showAlert(text: string)
		})
	```

	* `UIDevice.rx.orientation`이 `.landscape` 또는 `.portrait` 값을 생성할 때 마다, Rx는 각각의 연산자를 데이터의 형태로 방출함.
		* 먼저 `filter` 는 `.landscape` 가 아닌 값만을 내놓는다. 만약 디바이스가 landscape 모드라면 나머지 코드는 진행되지 않을 것이다. 왜냐하면 `filter`가 해당 이벤트의 실행을 막을 것이기 때문에. 
		* 만약 `.portrait` 값이 들어온다면, `map` 연산자는 해당 방향값을 택할 것이며 이것을 `String` 출력으로 변환할 것이다. ("`Portrait is the best!`")
		* 마지막으로, `subscribe`를 통해 결과로 `next` 이벤트를 구현하게 된다. 이번에는 `String` 값을 전달하고, 해당 텍스트로 alert을 화면에 표시하는 method를 호출한다.
* 연산자들은 언제나 입력된 데이터를 통해 결과값을 출력하므로, 단일 연산자가 독자적으로 할 수 있는 것보다 쉽게 연결 가능하며 훨씬 많은 것을 달성할 수 있다. 

### 3. Schedulers
* 스케줄러는 Rx에서 dispatch queue와 동일한 것. 다만 훨씬 강력하고 쓰기 쉽다.
* RxSwift에는 여러가지의 스케줄러가 이미 정의되어 있으며, 99%의 상황에서 사용가능하므로 아마 개발자가 자신만의 스케줄러를 생성할 일은 없을 것이다.
* 이 책의 초기 반 정도에서 다룰 대부분의 예제는 아주 간단하고 일반적인 상황으로, 보통 데이터를 관찰하고 UI를 업데이트 하는 것이 대부분이다. 따라서 기초를 완전히 닦기 전까지 스케줄러를 공부할 필요는 없다.
* (다만, 맛보기로..) 기존까지 GCD를 통해서 일련의 코드를 작성했다면 스케줄러를 통한 RxSwift는 다음과 같이 돌아간다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/01_HelloRxSwift/4.%20scheduler.png?raw=true" height = 200>
	
	* 각 색깔로 표시된 일들은 다음과 같이 각각 스케줄(1, 2, 3...)된다. 
		* `network subscription`(파랑)은 (1)로 표시된 `Custom NSOperation Scheduler`에서 구동된다.
		* 여기서 출력된 데이터는 다음 블록인 `Background Concurrent Scheduler`의 (2)로 가게 된다. 
		* 최종적으로, 네트워크 코드의 마지막 (3)은 `Main Thread Serial Scheduler`로 가서 UI를 새로운 데이터로 업데이트 하게 된다.
* 지금 스케줄러가 편리하고 흥미로워 보이더라도 너무 많은 스케줄러를 사용할 필요는 없다. 일단 기초부터 닦고 후반부에 깊이 들어가보자.

## E. App Architecture
* RxSwift는 기존의 앱 아키텍처에 영향을 주지 않는다. 주로 이벤트나 비동기 데이터 시퀀스 등을 주로 처리하기 때문이다. 
* 따라서 Apple 문서에서 언급된 MVC 아키텍처에 Rx를 도입할 수 있다. 물론 MVP, MVVM 같은 아키텍처를 선호한다면 역시 가능하다.
* Reactive 앱을 만들기 위해 처음부터 프로젝트를 시작할 필요도 없다. 기존 프로젝트를 부분적으로 리팩토링하거나 단순히 앱에 새로운 기능을 추가할 때도 사용가능하다.
* Microsoft의 MVVM 아키텍쳐는 데이터 바인딩을 제공하는 플랫폼에서 이벤트 기반 소프트웨어용으로 개발되었기 때문에, 당연히 RxSwift와 MVVM는 같이 쓸 때 아주 멋지게 작동한다. 
	* ViewModel을 사용하면 `Observable<T>` 속성을 노출할 수 있으며 ViewController의 UIKit에 직접 바인딩이 가능하다. 
	* 이렇게 하면 모델 데이터를 UI에 바인딩하고 표현하고 코드를 작성하는 것이 매우 간단해진다. 
* 이 책에서는 MVC 패턴을 사용한다. (왜 ㅠㅠ)
* 다음은 MVVM 아키텍처

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/01_HelloRxSwift/5.%20MVVM.png?raw=true" height = 200>


## F. RxCocoa
* RxCocoa는 RxSwift의 동반 라이브러리로, UIKit과 Cocoa 프레임워크 기반 개발을 지원하는 모든 클래스를 보유하고 있다.
	* RxSwift는 일반적인 Rx API라서, Cocoa나 특정 UIKit 클래스에 대한 아무런 정보가 없다.
* 예를들어, RxCocoa를 이용하여 `UISwitch`의 상태를 확인하는 것은 다음과 같이 매우 쉽다.

	```swift
	toggleSwitch.rx.isOn
		.subscribe(onNext: { enabled in
			print( enabled ? "It's ON" : "it's OFF")
		})
	```
	* RxCocoa는 `rx.isOn`과 같은 프로퍼티를 `UISwitch` 클래스에 추가해주며, 이를 통해 이벤트 시퀀스를 확인할 수 있다. 
* RxCocoa는 `UITextField`, `URLSession`, `UIViewController` 등에 `rx`를 추가하여 사용한다.

## G. Installing RxSwift
### 1. via CocoaPods

```
use_frameworks!

target 'MyTargetName' do
	pod 'RxSwift', '~> 4.0'
	pod 'RxCocoa', '~> 4.0'
end
```

### 2. via Carthage
```
github "ReactiveX/RxSwift" ~> 4.0
```

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
