# Ch.11 Time Based Operators

## A. 시작하기

* 시간의 흐름에 따라 데이터가 변동되는 것을 시각적으로 확인해볼 수 있다.

## B. Buffering operators

* Buffering 연산자들은 과거의 요소들을 구독자에게 다시 재생하거나, 잠시 버퍼를 두고 줄 수 있다.
* 언제 어떻게 과거와 새로운 요소들을 전달할 것인지 컨트롤 할 수 있게 해준다.

### 1. 과거 요소들 리플레이

* sequence가 아이템을 방출했을 때, 보통 미래의 구독자가 지나간 아이템을 받을 수 있는지 아닌지에 대한 여부는 항상 중요하다.
* 이들은 `replay(_:)`와 `replayAll()` 연산자를 통해 컨트롤 할 수 있다.
* 다음과 같은 코드를 작성해보자

	```swift
	let elementsPerSecond = 1
	let maxElements = 5
	let replayedElements = 1
	let replayDelay:TimeInterval = 3
	
	// 1
	let sourceObservable = Observable<Int>.create { observer in
	    var value = 1
	    let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main, handler: {
	    
	    	// 2
	        if value <= maxElements {
	            observer.onNext(value)
	            value += 1
	        }
	    })
	    return Disposables.create {
	        timer.suspend()
	    }
	}
		// 3
	    .replay(replayedElements)
	
	// 4
	let sourceTimeline = TimelineView<Int>.make()
	let replayedTimeline = TimelineView<Int>.make()
	
	// 5
	let stack = UIStackView.makeVertical([
	    UILabel.makeTitle("replay"),
	    UILabel.make("Emit \(elementsPerSecond) per second:"),
	    sourceTimeline,
	    UILabel.make("Replay \(replayedElements) after \(replayDelay) sec:"),
	    replayedTimeline])
	
	// 6
	_ = sourceObservable.subscribe(sourceTimeline)
	
	// 7
	DispatchQueue.main.asyncAfter(deadline: .now() + replayDelay) {
	    _ = sourceObservable.subscribe(replayedTimeline)
	}
	
	// 8
	_ = sourceObservable.connect()
	    
	// 9
	let hostView = setupHostView()
	hostView.addSubview(stack)
	hostView
	```
	
 	* 주석을 따라 하나씩 살펴보자.
 		* 1) `elementsPerSecond`에서 요소들을 방출할 observable을 만들어야 한다. 또한 방출된 요소의 개수와, 몇개의 요소를 새로운 구독자에게 "다시재생"할지 제어할 필요가 있다. 
 			* 이러한 observable을 방출하기 위해서 `Observable<T>`와  `create` 메소드를 사용해보자.
 			* `DispatchSource.timer` 함수는 playground 내 `Sources` 폴더에 정의된 `DispatchSource`의 extension이다. 이 함수를 통해 반복 타이머 생성을 단순화 할 수 있다. 
 		* 2) 이 예제의 목적은, observable의 *완료completing*에 대해 신경쓸 필요가 없다는 것이다. 여기서는 단순히 방출이 가능할 때까지 계속해서 요소들을 방출해 낸다.  
 		* 3) observable에 replay 기능을 추가하자. 
 			* 이 연산자는 source observable에 의해 방출된 마지막 `replayedElements`에 대한 기록을 새로운 sequence로 생성해낸다.
 			* 매번 새로운 observer가 구독될 때마다, 즉시 (만약 존재한다면) 버퍼에 있는 요소들을 받고, 새로한 요소들이 있다면 마치 일반적인 구독처럼 계속해서 구독을 하게 된다. 
 		* 4) `replay(:)`의 실제 효과를 시각화하기 위해, 한쌍의 `TimeLineView` 뷰를 생성하자. 
 			* `TimeLineView` 클래스는 playground 아래쪽 **Source** 그룹의 `TimeLineViewBase` 클래스에 정의되어 있다. 이 클래스는 observable의 이벤트 방출을 실시간으로 시각화해준다. 
 		* 5) 편의를 위해 `UIStackView`를 사용한다. 이 역시 추후 새로운 구독자 뷰가 나타날 때까지 실시간 source observable를 구독하는 뷰가 될 것이다.
 			* 복잡해보이지만 실제로는 매우 간단한 코드다. 단순히 수직적으로 뷰를 탏탏 쌓는 것.
 			* `UIStackView.makeVertical(_:)`과 `UILabel.make(_:)` 함수들은 편의를 위한 extension들이다.
 		* 6) 상단 timeline을 받아 화면에 띄울 구독자를 준비한다. 
 			* `TimelineView` 클래스는 `ObserverType` RxSwift 프로토콜을 준수한다. 따라서, `TimelineView` 클래스는 sequence의 이벤트를 받을 수도 있고, observable sequence 처럼 구독될 수도 있다. 
 			* 매번 새로운 이벤트가 발생(요소방출, 완료, 에러)될 때마다 `TimelineView`는 이들을 타임라인에 표시한다.
 			* 방출된 요소들은 초록색으로, 완료는 검은색, 에러는 빨간색으로 표시되게 된다.
 			* 여기까지의 코드를 확인해보면 구독에 의해 `Disposable`의 리턴값이 무시되는 것을 알 수 있다. 왜냐하면 playground 페이지가 새로고침 될때마다 작성한 예제 코드가 저장되지 않기 때문이다. 롱런하는 구독의 경우 `DisposeBag`을 이용하자. 
 		* 7) source observable을 다시 구독해보자. 단, 이번에는 약간의 딜레이를 주자. 
 			* 곧 두번째 타임라인에 두번째 구독을 통해 받은 요소들을 볼 수 있을 것이다.
 			* 이제 `replay(_:)`가 **connectable observable**을 생성하기 때문에 아이템을 받기 시작하려면 이것을 기본 소스에 연결해야 한다. 이 작업을 하지 않으면 구독자는 아무 값도 받지 못할 것이다. 
 		* 8) `.connect()` 한다. 
 			* `ConnectableObservable`은 observable의 계열의 특별한 클래스이다. 이들은 `connect()` 메소드를 통해 불리기 전까지는 구독자 수와 관계 없이, 아무 값도 방출하지 않는다. 이 장에서는 `ConnectableObservable<E>`(`Observable<E>` 아님.)를 리턴하는 연산자에 대해서 배우게 될 것이다. 해당 연산자들은 다음과 같다. 
 				* `replay(_:)`
 				* `replayAll()`
 				* `multicast(_:)`
 				* `publish()`   	 
 		* 9) 마지막으로, stack view가 표시될 host view를 구축하자. 
 			* 두 개의 타입라인을 확인할 수 있다. 위쪽의 타임라인은 `connect()`라는 observer를 반영하고 있다. 아래쪽의 타임라인은 딜레이 이후에 구독되는 observable을 보여주고 있다.
 
	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/11_Time%20Based%20Operators/1.%20result.png?raw=true" height = 300>
 
 	* 사용한 설정에서는 `replayedElements`는 `1`과 같다. 이는 `replay(_:)` 연산자가 source observable에서 마지막으로 방출하는 값만을 버퍼로 두기 때문이다. 
 	* 타임라인을 보면, 두번째 구독자가 `3`, `4` 요소들을 동시에 받은 것을 알 수 있다. 구독하는 시간에 따라, 마지막 버퍼값인 `3`과, 두번째 구독을 함으로써 받은 `4`를 동시에 받은 것이다. (사실 정확히 같은 순간은 아니다.)
 	* `replayDelay`와 `replayedElements` 값을 변경해가면서 플레이해보자. 

### 2. 무제한 리플레이

* 여기서 알아볼 연산자는 `replayAll()`이다. 이 녀석을 쓸 땐 주의할 것이 있다. (필요에 의해) 버퍼할 요소의 전체 개수를 정확히 알고 있는 상황에서 써야한다는 것이다.
* 예를 들어 HTTP request에서 쓸 수 있는데, 이 때 우리는 쿼리에서 반환하는 데이터를 유지할 경우 메모리에 줄 영향을 예측할 수 있다. 
* 반면에 `replayAll()`을 많은 양의 데이터를 생성하면서 종료도 되지 않는 sequence에 사용하면, 메모리는 금방 막히게 된다. App이 OS를 뒤흔들게 될 수도 있다. 주의할 것!
* `replayAll()`을 확인하기 위해, 상기 예제 코드의 `.replay(replayedElements)`를 `replayAll()`로 바꿔보자.
	* 두 번째 구독 즉시 모든 버퍼 요소들이 나타나게 된다. 

### 3. Controlled buffering

* `buffer(timeSpan:cout:scheduler:)` 연산자에 대해 알아보자. 다음 코드를 작성해봅시당.

	```swift
	// 1
	let bufferTimeSpan:RxTimeInterval = 4
	let bufferMaxCount = 2
	
	// 2
	let sourceObservable = PublishSubject<String>()
	
	// 3
	let sourceTimeline = TimelineView<String>.make()
	let bufferedTimeline = TimelineView<Int>.make()
	
	let stack = UIStackView.makeVertical([
	    UILabel.makeTitle("buffer"),
	    UILabel.make("Emitted elements:"),
	    sourceTimeline,
	    UILabel.make("Buffered elements (at most \(bufferMaxCount) every \(bufferTimeSpan) seconds:"),
	    bufferedTimeline])
	
	// 4
	_ = sourceObservable.subscribe(sourceTimeline)
	
	// 5
	sourceObservable
	    .buffer(timeSpan: bufferTimeSpan, count: bufferMaxCount, scheduler: MainScheduler.instance)
	    .map { $0.count }
	    .subscribe(bufferedTimeline)
	
	// 6
	let hostView = setupHostView()
	hostView.addSubview(stack)
	hostView
	
	// 7
	DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
	    sourceObservable.onNext("🐱")
	    sourceObservable.onNext("🐱")
	    sourceObservable.onNext("🐱")
	}
	```
	
	* 주석을 따라 확인해보자. 
		* 1) 기본적으로 쓰일 놈들을 정의합니다. 이들은 `buffer` 연산자 구현하기 위한 행동들을 정의하고 있다.
		* 2) 짧은 이모찌를 입력하게 될텐데, 이를 위해 PublishSubject<String>를 선언한다.  
		* 3) 위쪽 타임라인에서 구독할 이벤트를 위해 코드를 작성한다. **replay** 예제해서 했던 것과 같다.
		* 4) 버퍼된 타입라인은 각각의 버퍼어레이에 있는 요소들의 개수를 보여줄 것이다. 
		* 5) source observable의 array에 있는 요소들을 받고 싶다. 또한 각각의 array들은 **많아야** `bufferMaxCount`만큼의 요소들을 가질 수 있다. 만약 이 많은 요소들이 `bufferTimeSpan`이 만료되기 전에 받아졌다면, 연산자는 버퍼 요소들을 방출하고 타이머를 초기화 할 것이다. 마지막 그룹 방출 이후 `bufferTimeSpan`의 지연에서, **buffer**는 하나의 array를 방출할 것이다. 만약 이 지연시간동안 받은 요소가 없다면 array는 비게 될 것이다. 
		* 6) 타임라인 뷰를 활성화 하기 위해 작성한 코드다.
		 	* source observable에 아무런 활동이 없을지라도, 버퍼 타임라인에 빈 버퍼가 있다는 것을 확신할 수 있다.
		 	* `buffer(_:scheduler:)` 연산자는 source observable에서 받을 것이 없으면 일정 간격으로 빈 array를 방출한다. `0`는 source observable에서 0개의 요소가 방출되었음을 의미한다. 
		 	* 이제 source observable에 데이터를 공급할 수 있다. 버퍼링 된 observable에 어떤 영향이 나타나는지 확인해보자. 먼저 5초동안 3개의 요소를 집어 넣어보자. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/11_Time%20Based%20Operators/2.%20buffer.png?raw=true" height = 300>

	* 각각의 박스는 방출된 array들마다 몇개의 요소를 가지고 있는지 보여준다.
	* 최초에 버퍼 타임라인은 빈 array를 방출한다. - 왜냐하면 source observable에는 아직 아무런 요소가 없기 때문이다.
	* 이 후 세개의 요소가 source observable에 푸시 된다.
	* 버퍼 타임라인은 즉시 2개의 요소를 가진 하나의 array를 갖게 된다. 왜냐하면 `bufferMaxCount`에 `2`개라고 선언해놓았기 때문이다.
	* 4초가 지나고, 하나의 요소만을 가진 array가 방출된다. 이 것은 방출되어 source observable에 푸시된 3개의 요소중 마지막 요소이다.
* 상기 예제로부터 확인할 수 있듯이, 버퍼는 *전체용량full capacity*에 다다랐을 때 요소들의 array를 즉시 방출한다. 그리고 명시된 지연시간만큼 기다리거나 다시 전체용량이 채워질 때까지 기다린다. 
* 상기 예제에서 `DispatchQueue`를 지우고 다음 코드를 작성해보면, 또다른 버퍼 시나리오를 확인할 수 있다. 

	```swift
	let elementsPerSecond = 0.7
	let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
	    sourceObservable.onNext("🐱")
	}
	```
	
	* 1/0.7 간격으로 sourceObservable에 🐱를 푸시하게 된다. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/11_Time%20Based%20Operators/3.%20buffer.png?raw=true" height = 300>

### 4. buffered observables의 `window`

* `window(timeSpan:count:scheduler:)`는 `buffer(timeSpan:count:scheduler:)`와 아주 밀접하다. 대충 보면 거의 같아보인다. 유일하게 다른 점은 array 대신 `Observable`을 방출한다는 것이다. 
* 좀 더 정교한 타임라인 뷰를 만들어보자. `window` sequence는 여러 observable을 방출하므로 개별적으로 시각화하는 것이 좋다. 다음 코드를 살펴보자.

	```swift
	// 1
	let elementsPerSecond = 3
	let windowTimeSpan:RxTimeInterval = 4
	let windowMaxCount = 10
	let sourceObservable = PublishSubject<String>()
	
	// 2
	let sourceTimeline = TimelineView<String>.make()
	
	let stack = UIStackView.makeVertical([
	    UILabel.makeTitle("window"),
	    UILabel.make("Emitted elements (\(elementsPerSecond) per sec.):"),
	    sourceTimeline,
	    UILabel.make("Windowed observables (at most \(windowMaxCount) every \(windowTimeSpan) sec):")])
	
	// 3
	let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
	    sourceObservable.onNext("🐱")
	}
	
	// 4
	_ = sourceObservable.subscribe(sourceTimeline)
	
	// 5
	_ = sourceObservable
	    .window(timeSpan: windowTimeSpan, count: windowMaxCount, scheduler: MainScheduler.instance)
	    .flatMap { windowedObservable -> Observable<(TimelineView<Int>, String?)> in
	        let timeline = TimelineView<Int>.make()
	        stack.insert(timeline, at: 4)
	        stack.keep(atMost: 8)
	        return windowedObservable
	            .map { value in (timeline, value)}
	            .concat(Observable.just((timeline, nil)))
	}
		// 6
	    .subscribe(onNext: { tuple in
	        let (timeline, value) = tuple
	        if let value = value {
	            timeline.add(.Next(value))
	        } else {
	            timeline.add(.Completed(true))
	        }
	    })
	
	// 7
	let hostView = setupHostView()
	hostView.addSubview(stack)
	hostView
	```
	
	* 하나씩 살펴봅시당.
		* 1) `String`을 PublishSubject로 푸시하여 출력된 observable 항목에서 시간별로 출력을 그룹화 하려고 한다.
		* 2) 요소들을 source observable에 푸시하기 위한 타이머를 추가하자.
		* 3) source timeline을 채운다.
		* 4) 각각의 방출된 observable이 분리되어 볼 수 있게 한다. 매번 `window(timeSpan:count:scheduler:)`가 새로운 observable을 방출할 때마다 새로운 타입라인을 삽입한다. 이전 observable들은 아래로 내려가야 한다. 
			* 이 코드는 windowed observable이다. 어떻게 방출될 observable을 관리할 수 있을까? 
		* 5) `flatMap(_:)` 연산자를 쓸 수 있을 것이다. 
			* `flatMap(-:)`이 새로운 observable을 받을 때 마다, 새로운 타임라인 뷰를 삽입한다.
			* 반환된 observable들을 `timeline`과 `value`를 조합한 튜플로 매핑한다. 이 목적은 두 값을 표시할 수 있는 곳으로 같이 옮기려는 것이다.
			* 내부의 observable이 일단 완료되면, `concat(_:)`으로 하나의 튜플을 연결한다. 이를 통해 타임라인이 완료되었음을 표시할 수 있게 된다.
			* `flatMap(_:)`으로 결과값(observable의 observable)을 하나의 tuple sequence로 변환할 수 있다.
			* 결과 observable을 구독하고 타임라인을 받은 tuple로 채운다. 
		* 6) 이제 구독하여 요소들을 각각의 타임라인에 표시해야 한다. 
			* 여기서 tuple속 `value`는 `String?` 타입이다. 만약 값이 `nil`이라면 sequence가 종료되었음을 의미한다. 
		* 7) 화면에 표시한다.   

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/11_Time%20Based%20Operators/4.%20window.png?raw=true" height = 600 >

	* 두번째 타임라인부터 살펴보면, 모든 타임라인은 "가장 최근의 것" 이다. 이 그림은 windowed observable당 최대 5개 요소를 가지고 4초마다 `window` 되도록 했다. 이 것은 새로운 observable이 적어도 4초마다 생성된다는 것을 의미한다. 5개의 요소를 모은 순간에 방출될 것이다.
	* source observable이 window 될 동안 4개보다 많은 요소를 방출하면, 새로운 observable이 생성되고, 다시 이 과정을 반복하게 된다. 

## C. Time-shifting operators

### 1. 구독 지연

* `delaySubscription(_:scheduler:)`에 대해서 알아보자. 지금까지 타임라인 애니메이션 만드는 것은 많이 해봤으니까, 이번에는 간단히 `delaySubscription`에 해당하는 부분만 설명하겠다.

	```swift
	_ = sourceObservable
    	.delaySubscription(RxTimeInterval(delayInSeconds), scheduler: MainScheduler.instance)
    	.subscribe(delayedTimeline)
	```
	
	* 이름에서 유추할 수 있듯이, 구독을 시작한 후 요소를 받기 시작하는 시점을 지연하는 역할을 한다.
	* `delayInSeconds`에 정의된 것에 따라 지연 이후 보여질 요소들을 선택하기 시작한다. 

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/11_Time%20Based%20Operators/5.%20delay.png?raw=true" height = 300>

* Rx에서 observable에 대해 "cold" 또는 "hot"이라 명명한다. "cold" observable들은 요소를 등록할 때, 방출이 시작된다. "hot" observable들은 어떤 시점에서부터 영구적으로 작동하는 것이다. (Notifications 같은) 구독을 지연시켰을 때, "cold" observable이라면 지연에 따른 차이가 없다. "hot" observable이라면 예제에서와 같이 일정 요소를 건너뛰게 된다. 정리하면, "cold" observable은 구독할 때만 이벤트를 방출하지만, "hot" observable은 구독과 관계없이 이벤트를 방출한다는 것이다. 
	
### 2. Delayed elements

* RxSwift에서 또 다른 종류의 delay는 전체 sequence를 뒤로 미루는 작용을 한다.
* 구독을 지연시키는 대신, source observable을 즉시 구독한다. 다만 요소의 방출을 설정한 시간만큼 미룬다는 것이다.
* 상단의 `delaySubscription(_:scheduler:)` 대신에 아래의 코드를 추가해보자.

	```swift
	_ = sourceObservable
	    .delay(RxTimeInterval(delayInSeconds), scheduler: MainScheduler.instance)
	    .subscribe(delayedTimeline)
	```
	
<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/11_Time%20Based%20Operators/6.%20delay.png?raw=true" height = 300>

## D. Timer operators

* 어떤 application이든 *timer*를 필요로 한다. iOS와 macOS에는 이에 대해 다양한 솔루션들이 있다. 통상적으로, `NSTimer`가 해당 작업을 수행했지만, 혼란스러운 소유권 모델을 가지고 있어 적절한 사용이 어려웠다.
* 좀 더 최근에는 `dispatch` 프레임워크가 dispatch 소스를 통해 타이머를 제공했다. 확실히 `NSTimer`보다는 나은 솔루션이지만, API는 여전히 랩핑 없이는 복잡하다. 
* RxSwift는 간단하고 효과적인 솔루션을 제공한다. 

### 1. Observable.interval(_:scheduler:)

* `DispatchSource`를 이용해서 일정간격의 타이머를 만들어볼 것이다. 또한 이 것을 `Observable.interval(_:scheduler:)` 인스턴스로 전환할 수도 있다. 이들은 정의된 스케줄러에서 선택된 간격으로 일정하게 전송된 `Int`값의 무한한 observable을 생성한다. (사실상 카운터다.)
* **replay** 예제에서 `DispatchSource.timer(_:queue:)` 을 포함하는 Observable 부분을 모두 삭제하고 하기 코드를 삽입해보자

	```swift
	let sourceObservable = Observable<Int>
	    .interval(RxTimeInterval(1.0 / Double(elementsPerSecond)), scheduler: MainScheduler.instance)
	    .replay(replayedElements)
	```
	
* RxSwift에서 interval timer들을 생성하는 것은 아주 쉽다. 생성 뿐만 아니라 취소하는 것도 쉽다. 
	* `Observable.interval(_:scheduler:)`은 observable 을 생성하므로 구독은 손쉽게 `dispose()`로 취소할 수 있다. 구독이 취소된다는 것은 즉 타이머를 멈춘다는 것을 의미한다.
* observable에 대한 구독이 시작된 이후 정의된 간격동안 첫번째 값을 방출 시킬 수 있는 아주 명확한 방법이다. 또한 타이머는 이 시점 이전에는 절대 시작하지 않는다. 구독은 시작을 위한 방아쇠 역할을 하게 되는 것이다. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/11_Time%20Based%20Operators/7.%20timer.png?raw=true" height = 300>

	* 타임라인에서 확인할 수 있듯이, `Observable.interval(_:scheduler:)`를 통해 방출된 값은 `0`부터 시작한다. 다른 값이 필요하다면, `map(_:)`을 이용할 수 있다. 
	* 현업에서는 보통, 타이머를 통해 값을 방출하진 않는다. 다만 아주 편리하게 index를 생성할 수 있는 방법이 된다.

### 2. Observable.timer(_:period:scheduler:)

* 좀 더 강력한 타이머를 원한다면 `Observable.timer(_:period:scheduler:)` 연산자를 사용할 수 있다. 이 연산자는 앞서 설명한 `Observable.interval(_:scheduler:)`과 아주 유사하지만 몇가지 차이점이 있다.
	* 구독과 첫번째 값 방출 사이에서 "마감일"을 설정할 수 있다. 
	* 반복기간은 *옵셔널*이다. 만약 반복기간을 설정하지 않으면 타이머 observable은 한번만 방출된 뒤 완료될 것이다.
* **delay** 예제로 가서, `delay(_:scheduler:)` 연산자를 사용한 부분을 아래 코드로 바꿔보자.

	```swift
	_ = Observable<Int>
	    .timer(3, scheduler: MainScheduler.instance)
	    .flatMap { _ in
	        sourceObservable.delay(RxTimeInterval(delayInSeconds), scheduler: MainScheduler.instance)
	    }
	    .subscribe(delayedTimeline)
	``` 
	
	* 다른 타이머를 트리거하는 타이머? 이렇게 하면 어떤 이점이 있을까?
		* 가독성이 좋다. (좀 더 Rx 답다.)
		* 구독이 disposable을 리턴하기 때문에, 첫번째 또는 두번째 타이머가 하나의 observable과 함께 트리거 되기 전, 언제든지 취소할 수 있다.
		* `flatMap(_:)` 연산자를 사용하므로써, `Dispatch`의 비동기 클로저를 사용하지 않고도 타이머 sequence들을 만들 수 있다. 

### 3. Timeout

* `timeout`연산자의 주된 목적은 타이머를 시간초과(오류) 조건에 대해 구별하는 것이다. 따라서 `timeout` 연산자가 실행되면, `RxError.TimeoutError`라는 에러 이벤트를 방출한다. 만약 에러가 잡히지 않으면 sequence를 완전 종료한다.
* 아래의 코드를 살펴보자.

	```swift
	// 1
	let button = UIButton(type: .system)
	button.setTitle("Press me now!", for: .normal)
	button.sizeToFit()
	
	// 2
	let tapsTimeline = TimelineView<String>.make()
	
	let stack = UIStackView.makeVertical([
	    button,
	    UILabel.make("Taps on button above"),
	    tapsTimeline])
	
	// 3
	let _ = button
	    .rx.tap
	    .map { _ in "●" }
	    .timeout(5, scheduler: MainScheduler.instance)
	    .subscribe(tapsTimeline)
	
	// 4
	let hostView = setupHostView()
	hostView.addSubview(stack)
	hostView
	```
	
	* 주석을 따라 하나씩 살펴보자.
 		* 1) 간단한 버튼을 하나 만들었습니다. 이 것은 RxCocoa 라이브러리를 활용한 것으로 자세한 것은 나중에 배울 것임. 아무튼 여기서 구현한 것은 다음과 같습니다.
 			* 버튼 탭을 캡쳐하는 것
 			* 만약 버튼이 5초 이내로 눌렸다면 뭔가를 프린팅하고 5초 이내 다시 눌려지지 않으면 sequence를 완전 종료한다.
 			* 만약 버튼이 눌려지지 않았다면 에러 메시지를 프린트 한다. 
 		* 2) 버튼이 눌릴 때마다 쌓을 뷰를 만든다
 		* 3) observable을 구축하고 타임라인 뷰와 연결한다.
 		* 4) 뷰를 띄운다.
 * `timeout(_:scheduler:)`의 다른 버전은 observable을 취하고 타임아웃이 시작되었을 때, 에러대신 취한 Observable을 방출한다. 상기 `timeout(_:scheduler:)` 부분을 아래 코드로 바꿔보자.

	```swift
	   .timeout(5, other: Observable.just("X"), scheduler: MainScheduler.instance)
	```
 	
 	* 상기 코드에선 빨간색의 에러 이벤트를 방출했지만, 이번에는 초록색의 일반적인 완료 이벤트가 "X" 요소와 함께 방출된다. 

## E. Challenges

### 부수작용 억제하기

* `window(_:scheduler)` 연산자에 대한 예제에서, 우리는 타임라인을 `flatMap(:_)` 연산자의 클로저 내부에 생성했다. 
* 이 작업은 코드를 간략하게 만들기 위함이었지만, 반응형 프로그래밍의 가이드라인 중 하나는 "*단일체monad*에서 벗어나지 말 것" 이다. 다시 말하면 부수작용을 최대한 내지 말라는 것이다. 
* 여기서의 부작용은 변형만 발생해야하는 시점에 새 타임라인도 생성되는 것이다. 
* 따라서 기존에 작성한 코드 대신에 다른 방법을 찾는 것이 이번 과제다. 물론 다양한 방법이 있을 수 있지만, 가장 효과적인 방법은, 작업을 여러개의 observable로 나누고, 추후에 이들을 합치는 방법일 것이다.
	* windowed observable들을 하나씩 나누는 방법은 타임라인 뷰를 준비하고 (`do(onNext:)` 연산자를 통해 부작용이 발생할 수 있음을 인지할 것),
	* 생성된 타임라인 뷰와 source sequence의 요소를 사용하여, (힌트. `zip`과 `flatMap`을 조합해볼 것)
	* `window`가 새로운 sequence를 내보낼 때마다 상황에 따른 값 (타임라인 뷰와 sequence)를 생성한다.

> A.
>
> ```swift
> let windowedObservable = sourceObservable
>     .window(timeSpan: windowTimeSpan, count: windowMaxCount, scheduler: MainScheduler.instance)
> 
> let timelineObservable = windowedObservable
>     .do(onNext: { _ in
>         let timeline = TimelineView<Int>.make()
>         stack.insert(timeline, at: 4)
>         stack.keep(atMost: 8)
>     })
>     .map { _ in
>         stack.arrangedSubviews[4] as! TimelineView<Int>
> }
> 
> _ = Observable
>     .zip(windowedObservable, timelineObservable) { obs, timeline in
>         (obs, timeline)
>     }
>     .flatMap { tuple -> Observable<(TimelineView<Int>, String?)> in
>         let obs = tuple.0
>         let timeline = tuple.1
>         return obs
>             .map { value in (timeline, value) }
>             .concat(Observable.just((timeline, nil)))
>     }
> ```

* 기존 `window`가 부수작용을 내는지 확인하기 어렵기 때문에 `do(onNext:)`를 통해 스택뷰에 영향을 주는 놈들을 표시한다. 
	* 사실 기존 코드대로 사용해도 크게 문제가 생기는 것은 아니다. 다만 windowed observable에서 `stack`의 `.insert`와 `.keep`은 .do에 있는게 맞고 .map에는 사용하지 않는것이 맞다고 판단되는 것.
* 모나드란?
	* 위키를 확인하세요.
	* `.map`, `.flatten`, `.flatMap`을 최소조건으로 해서 적용 가능한 모든 Generic들
	* 예) array, optional 등

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com