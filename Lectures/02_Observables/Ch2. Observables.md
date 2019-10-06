# Ch.2 Observable

## A. 시작하기
* 예제로 제공된 `RxSwiftPlayground.playground` 파일을 이용해 공부할 것
* `.playground` 파일에 직접 연결하지 말고 `.xcworkspace` 파일을 통해 `.playground`를 확인할 수 있으니 주의
* `.xcworkspace` > `.playground` 파일 하단의 `Sources` 폴더를 보면 `SupportCode.swift` 파일이 있으며, 여기엔 필요한 부분에 대한 예제를 볼 수 있는 도우미 method가 아래와 같이 정의되어 있으니 참고

```swift
public func example(of description: String, action: () -> Void) {
	print("\n--- Example of:", description, "---")
	action()
}
```


## B. Observable 이란?
* Rx의 심장
* Observable이 무엇인지, 어떻게 만드는지, 어떻게 사용하는지에 대해서 알아볼 것임
* `observable` = `observable sequence` = `sequence`: 각각의 단어를 계속 보게 될 것인데 이는 곧 다 같은 말이다. (Everything is a sequence)
* 중요한 것은 이 모든 것들이 **비동기적(asynchronous**)이라는 것.
* Observable 들은 일정 기간 동안 계속해서 **이벤트**를 생성하며, 이러한 과정을 보통 **emitting**(방출)이라고 표현한다. 
* 각각의 이벤트들은 숫자나 커스텀한 인스턴스 등과 같은 **값**을 가질 수 있으며, 또는 탭과 같은 **제스처**를 인식할 수도 있다. 
* 이러한 개념들을 가장 잘 이해할 수 있는 방법은 marble diagrams를 이용하는 것이다. 
	* marble diagram?: 시간의 흐름에 따라서 값을 표시하는 방식
	* 시간은 왼쪽에서 오른쪽으로 흐른다는 가정
	* 참고하면 좋을 사이트: [RxMarbles](http://rxmarbles.com) 

## C. Observable의 생명주기

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/02_Observables/1.%20marble.png?raw=true" height = 50>

* 상단의 Marble diagram을 보면 세 개의 구성요소를 확인 할 수 있다. 
* Observable은 앞서 설명했던 `next` 이벤트를 통해 각각의 요소들을 방출하는 것.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/02_Observables/2.%20lifecycle1.png?raw=true" height = 50>

* 이 Observable은 세 개의 tap 이벤트를 방출한 뒤 완전종료됨. 이 것을 앞서 말한 대로 `completed` 이벤트라고 한다.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/02_Observables/3.%20lifecycle2.png?raw=true" height = 50>

* 이 marble diagram에서는 상단의 예시들과 다르게 에러가 발생한 것.
* Observable이 완전종료되었다는 면에선 다를게 없지만, `error` 이벤트를 통해 종료된 것

> 정리하면, 
>
> * Observable은 어떤 구성요소를 가지는 `next` 이벤트를 계속해서 방출할 수 있다.
> * Observable은 `error` 이벤트를 방출하여 완전 종료될 수 있다.
>
> * Observable은 `complete` 이벤트를 방출하여 완전 종료 될 수 있다.

* RxSwift 소스코드 예제를 살펴보자. 예제에서 이러한 이벤트들은 enum 케이스로 표현되고 있다.

	```swift
	/// Represents a sequence event.
	///
	/// Sequence grammar:
	/// **next\* (error | completed)**
	public enum Event<Element> {
		/// Next elemet is produced.
		case next(Element)
		
		/// Sequence terminated with an error.
		case error(Swift.Error)
		
		/// Sequence completed successfully.
		case completed
	}
	``` 
	* 여기서 `.next` 이벤트는 어떠한 `Element` 인스턴스를 가지고 있는 것을 확인할 수 있다. 
	* `.error` 이벤트는 `Swift.Error` 인스턴스를 가진다.
	* `completed` 이벤트는 아무런 인스턴스를 가지지 않고 단순히 이벤트를 종료시킨다. 


## D. Observable 만들기

* `RxSwift.playground`에 하단의 코드를 추가해봅시다.

	```swift
	example(of: "just, of, from") {
	    // 1
	    let one = 1
	    let two = 2
	    let three = 3
	    
	    //2
	    let observable:Observable<Int> = Observable<Int>.just(one)
	}
	``` 
	* 이 코드로 해야할 것
		* i) 다음 예제에서 사용할 Int 상수를 정의
		* ii) `one` 정수를 이용한 `just` method를 통해 `Int` 타입의 Observable sequence를 만들 것
	* `just`는 `Observable`의 타입 메소드. 이름에서 추측할 수 있듯, 오직 하나의 요소를 포함하는 Observable sequence를 생성한다.
		* 내가 이해한게 맞다면 상기코드의 `observable`은 `1` 을 뿜! 할 듯.
	* Rx에는 ***operator***(연산자)가 있으니 이걸 이용할 수 있을 것임
* 상기 코드 하단에 아래 코드를 추가해봅시다.

	```swift
	let observable2 = Observable.of(one, two, three)
	```  
	* `observable2`의 타입은 `Observable<Int>`
	* `.of` 연산자는 주어진 값들의 타입추론을 통해 `Observable` sequence를 생성함.
	* 따라서, 어떤 array를 observable array로 만들고 싶다면, array를 `.of` 연산자에 집어 넣으면 된다.
	* [Marble diagram 확인](http://rxmarbles.com/#of)

* 아래 코드도 추가해 봅시다.

	```swift
	let observable3 = Observable.of([one, two, three])
	```
	* `observable3`의 타입은 `Observable<[Int]>`
	* 이렇게 하면 `just` 연산자를 쓴 것과 같이 `[1,2,3]`를 단일요소로 가지게 된다. 

* `Observable`을 만들 수 있는 또다른 연산자는 `from` 이다.
	```swift
	let observable4 = Observable.from([one, two, three])
	``` 
	* `observable4`의 타입은 `Observable<Int>`
	* `from` 연산자는 일반적인 array 각각 요소들을 하나씩 방출한다
	* `from` 연산자는 ***오직 array 만*** 취한다.
	* [Marble diagram 확인](http://rxmarbles.com/#from)

## E. Observable 구독

> Tip: 사실 구독이라 표현한 부분은 *subscribing*을 사전적의미 그대로 번역한 것에 불과합니다. 그래서 정확히 어떤 의미인지 두호님께 물어봤었는데, 사실 각각의 케이스에 대해서 해당 *subscribing*이 어떤 의미인지 질문을 한다면 명확한 답을 드릴 수 있지만, 단순히 Observable에서 *subscribing*이 어떤 의미인지 이해하시려면 여러가지 케이스와 경험을 통해서 그 느낌을 축적하시는 수 밖에 없다고 하시네요. 그래서 일단은 하단의 내용처럼 책에서 서술한 내용을 단순번역 해보겠습니다. 그리고 시간이 지나서 다시 읽어보면 수정할 부분이 많이 생길 것 같습니다. 

* iOS 개발자라면 `NotificationCenter`에 익숙할 것이다. 하단의 예제는 클로저 문법을 이용해서  `UIKeyboardDidChangeFrame` notification의 observer를 나타낸 것이다.

	```swift
	let observer = NotificationCenter.default.addObserver(
		forName: .UIKeyboardDidChangeFrame,
		object: nil,
		queue: nil
	) { notification in
		// Handle receiving notification
	}
	```
	* RxSwift의 Observable를 구독하는 것은 상기 방식과 비슷하다. 
		* Observable을 구독하고 싶을 때 구독(subscribe)!을 선언한다.
		* 따라서 `addObserver()` 대신에 `subscribe()`를 사용함.
		* 다만 상기코드가 `.default` 싱글톤 인스턴스에서만 가능했다면, Rx의 Observable의 경우는 그렇지 않다.
* **(중요)** Observable은 실제로 sequence 정의일 뿐이다. **Observable은 subscriber, 즉 구독되기 전에는 아무런 이벤트도 보내지 않는다.** 그저 정의일 뿐.
* Observable 구현은 Swift 기본 라이브러리의 반복문에서 `.next()`를 구현하는 것과 매우 유사하다.

	```swift
	let sequence = 0..<3
	var iterator = sequence.makeIterater()
	while let n = iterator.next() {
		print(n)
	}
	
	/* Prints:
	 0
	 1
	 2
	 */
	```
	* Observable 구독은 이보다 더 간단하다.
	* Observable이 방출하는 각각의 이벤트 타입에 대해서 handler를 추가할 수 있다.
	* Observable은 `.next`, `.error`, `.completed` 이벤트들을 다시 방출할 것이다.
		* `.next`는 handler를 통해 방출된 요소를 패스할 것이고,
		* `.error`는 error 인스턴스를 가질 것

### 1. .subscribe()
* `RxSwift.playground`에 하단의 코드를 추가해봅시다.

	```swift
	example(of: "subscribe") {
	    let one = 1
	    let two = 2
	    let three = 3
	    
	    let observable = Observable.of(one, two, three)
	    observable.subscribe({ (event) in
       	 print(event)
    	})
    	
    	/* Prints:
    	 next(1)
		 next(2)
		 next(3)
		 completed
    	*/
	}
	```
	* `.subscribe`는 escaping 클로저로 `Int`타입을 `Event`로 갖는다. escaping에 대한 리턴값은 없으며(Void) `.subscribe`은 (곧 배울) `Disposable`을 리턴한다.
	* 프린트된 값을 보면, Observable은 
		* i) 각각의 요소들에 대해서 `.next` 이벤트를 방출했다.
		* ii) 최종적으로 `.completed`를 방출했다.
	* Observable을 이용하다보면, 대부분의 경우 Observable이 `.next` 이벤트를 통해 방출하는 요소에 가장 관심가지게 될 것이다.

### 2. .subscribe(onNext:)
* 상기의 코드를 다음과 같이 바꿔보면,

	```swift
	observable.subscribe { event in
		if let element = event.element {
			print(element)
		}
	}
	
	/* Prints:
	 1
	 2
	 3
	*/
	``` 
	* 아주 자주 쓰이는 패턴이기 때문에 RxSwift에는 이 부분에 대한 축약형들이 있다.
	* 즉, Observable이 방출하는 `.next`,`.error`,`.completed` 같은 각각의 이벤트들에 대해 `subscribe` 연산자가있다.
* 상기의 코드를 다음과 같이 바꿔보면,

	```swift
	observable.subscribe(onNext: { (element) in
		print(element)
	})
	
	/* Prints:
	 1
	 2
	 3
	*/
	``` 
	* `.onNext` 클로저는 `.next` 이벤트만을 argument로 취한 뒤 핸들링할 것이고, 다른 것들은 모두 무시하게 된다.

### 2. .empty()
* 지금까지는 하나 또는 여러개의 요소를 가진 Observable만 만들었다. 그렇다면 요소를 하나도 가지지 않는 (count = 0) Observable은 어떻게 될까? `empty` 연산자를 통해 `.completed` 이벤트만 방출하게 된다.

	```swift
	example(of: "empty") {
	    let observable = Observable<Void>.empty()
	    
	    observable.subscribe(
	        
	        // 1
	        onNext: { (element) in
	            print(element)
	    },
	        
	        // 2
	        onCompleted: {
	            print("Completed")
	    }
	    )
	}
	
	/* Prints:
	 Completed
	*/
	```
	* Observable은 반드시 특정 타입으로 정의되어야 한다. 
	* 이 예제의 경우 타입추론할 것이 없기 때문에 (가지고 있는 요소가 없으므로) 타입을 명시적으로 정의해줘야 하며, 따라서 `Void` 는 아주 적절한 타입이 될 것이다. 
	* 주석으로 표기한 각 번호를 따라가보면
		* 1) `.next` 이벤트를 핸들링 한다.
		* 2) `.completed` 이벤트는 어떤 요소를 가지지 않으므로 단순히 메시지만 프린트 한다. 
	* 그렇다면 대체 `empty` Observable의 용도는 뭐가 있을까? 
		* 즉시 종료할 수 있는 Observable을 리턴하고 싶을 때
		* 의도적으로 0개의 값을 가지는 Observable을 리턴하고 싶을 때

### 3. .never()
* `empty`와는 반대로 `never` 연산자가 있다.

	```swift
	example(of: "never") {
	    let observable = Observable<Any>.never()
	    
	    observable
	        .subscribe(
	            onNext: { (element) in
	                print(element)
	        },
	            onCompleted: {
	                print("Completed")
	        }
	    )
	}
	```
	* 이렇게 하면 `Completed` 조차 프린트 되지 않는다.
	* 이 코드가 제대로 작동하는지 어떻게 확인할 수 있을까? 이 부분은 [Challenges](https://github.com/fimuxd/RxSwift/blob/master/Lectures/02_Observables/Ch2.%20Observables.md#1-부수작용-구현해보기-do-연산자) 섹션에서 알아보도록 하자

### 4. .range()

* 하기 코드를 생각해보자

	```swift
	example(of: "range") {
	    
	    //1
	    let observable = Observable<Int>.range(start: 1, count: 10)
	    
	    observable
	        .subscribe(onNext: { (i) in
	            
	            //2
	            let n = Double(i)
	            let fibonacci = Int(((pow(1.61803, n) - pow(0.61803, n)) / 2.23606).rounded())
	            print(fibonacci)
	        })
	}
	```
	* 주석대로 하나씩 살펴보면,
		* 1) `range` 연산자를 이용해서 `start` 부터 `count`크기 만큼의 값을 갖는 Observable을 생성한다.
		* 2) 각각 방출된 요소에 대한 n번째 피보나치 숫자를 계산하고 출력한다.
	* 추후 Ch7. Transforming Operators 에서 배울 내용에는, 방출된 요소들을 변형하는 방법으로 `onNext` 핸들러보다 더 나은 방법들을 배울 수 있다.
	
## F. Disposing과 종료
* **(한번더, 중요) Observable은 subscription을 받기 전까진 아무 짓도 하지 않음.**
* 즉, subscription이 Observable이 이벤트들을 방출하도록 해줄 방아쇠 역할을 한다는 의미
* 따라서 (반대로 생각해보면) Observable에 대한 구독을 취소함으로써 Observable을 수동적으로 종료시킬 수 있다.

### 1. .dispose()
* 하기의 코드를 살펴보자

	```swift
	example(of: "dispose") {
	    
	    // 1
	    let observable = Observable.of("A", "B", "C")
	    
	    // 2
	    let subscription = observable.subscribe({ (event) in
	        
	        // 3
	        print(event)
	    })
	    
	    subscription.dispose()
	}
	```
	* 주석대로 하나씩 살펴보면, 
		* 1) 어떤 string 의 Observable을 생성
		* 2) 이 Observable을 구독해봅니다. 여기서는 `subscripe`를 이용해 `Disposable`을 리턴하도록 한다.
		* 3) 출력된 각각의 이벤트들을 프린트 한다.
	* 여기서 구독을 취소하고 싶으면 `dispose()`를 호출하면 된다. 구독을 취소하거나 *dispose* 한 뒤에는 이벤트 방출이 정지된다.
    * 현재 `observable` 안에는 3개의 요소만 있으므로 `dispose()` 를 호출하지 않아도 `Completed`가 프린트 되지만, 요소가 무한히 있다면 `dispose()` 를 호출해야 `Completed` 가 프린트 된다.

### 2. DisposeBag()
* 각각의 구독에 대해서 일일히 관리하는 것은 효율적이지 못하기 때문에, RxSwift에서 제공하는 `DisposedBag` 타입을 이용할 수 있다. 
* `DisposeBag`에는 (보통은 `.disposed(by:)` method를 통해 추가된) disposables를 가지고 있다.
* disposable은 dispose bag이 할당 해제 하려고 할 때마다 dispose()를 호출한다.
* 하기의 코드를 살펴보자

	```swift
	example(of: "DisposeBag") {
	    
	    // 1
	    let disposeBag = DisposeBag()
	    
	    // 2
	    Observable.of("A", "B", "C")
	        .subscribe{ // 3
	            print($0)
	        }
	        .disposed(by: disposeBag) // 4
	}
	```
	* 주석대로 하나씩 살펴보면,
		* 1) dispose bag을 만든다
		* 2) observable을 만든다
		* 3) 방출하는 이벤트를 프린팅한다.
		* 4) `subscribe`로부터 방출된 리턴 값을 `disposeBag`에 추가한다.
	* 이러한 패턴은 앞으로 아주 흔하게 사용하게 될 패턴이다. (observable에 대해 subscribing 하고 이 것을 즉시 dispose bag에 추가하는 것)
* 귀찮게 이런 짓을 왜 매번 해야하는걸까?
	* 만약 dispose bag을 subscription에 추가하거나 수동적으로 `dispose`를 호출하는 것을 빼먹는다면, 당연히 메모리 누수가 일어날 것이다. 
	* 하지만 걱정마. Swift 컴파일러가 disposable을 쓰지 않을 때마다 경고를 날려줄거임 ^^

### 3. .create(:)
* 앞서 `.next` 이벤트를 이용해서 Observable을 만들었듯이, `.create` 연산자로 만드는 다른 방법이 있다.
* 하기 코드를 살펴보자

	```swift
	example(of: "create") {
	    let disposeBag = DisposeBag()
	    
	    Observable<String>.create({ (observer) -> Disposable in
	        // 1
	        observer.onNext("1")
	        
	        // 2
	        observer.onCompleted()
	        
	        // 3
	        observer.onNext("?")
	        
	        // 4
	        return Disposables.create()
	    })
	}
	```

	* `create` 는 escaping 클로저로, escaping에서는 `AnyObserver`를 취한 뒤 `Disposable`을 리턴한다. 
	* 여기서 `AnyObserver`란 generic 타입으로 Observable sequence에 값을 쉽게 추가할 수 있다. 추가한 값은 subscriber에 방출된다.
	* 주석대로 하나씩 살펴보면,
		* 1) `.next` 이벤트를 Observer에 추가한다. `onNext(_:)`는 `on(.next(_:))`를 편리하게 쓰는 용도
		* 2) `.completed` 이벤트를 Observer에 추가한다. `onCompleted` 역시 `on(.completed)`를 간소화한 것
		* 3) 추가로 `.next` 이벤트를 추가한다.
		* 4) disposable을 리턴한다.
	* 여기서 두번째 `.onNext` 이벤트의 요소인 `?`는 subscriber에 방출될까? 되지 않을까? 아래와 같이 `subscribe`를 찍어보면, 
		```swift
		example(of: "create") {
		    let disposeBag = DisposeBag()
		    
		    Observable<String>.create({ (observer) -> Disposable in
		        // 1
		        observer.onNext("1")
		        
		        // 2
		        observer.onCompleted()
		        
		        // 3
		        observer.onNext("?")
		        
		        // 4
		        return Disposables.create()
		    })
		        .subscribe(
		            onNext: { print($0) },
		            onError: { print($0) },
		            onCompleted: { print("Completed") },
		            onDisposed: { print("Disposed") }
		    ).disposed(by: disposeBag)
		}
		
		/* Prints:
		 1
		 Completed
		 Disposed
		*/
		```
		
		* `.onCompleted()`를 통해서 해당 Observable은 종료되었으므로, 두번째 `onNext(_:)`는 방출되지 않는다.
	* 만약에 여기에 에러를 추가한다면 어떻게 될까? 하기의 코드를 상단의 예제 이전에 입력해보면 에러를 통해 종료된다.
		```swift
		enum MyError: Error {
		    case anError
		}
		
		example(of: "create") {
		    let disposeBag = DisposeBag()
		    
		    Observable<String>.create({ (observer) -> Disposable in
		        // 1
		        observer.onNext("1")
		        
		        // 5
		        observer.onError(MyError.anError)
		        
		        // 2
		        observer.onCompleted()
		        
		        // 3
		        observer.onNext("?")
		        
		        // 4
		        return Disposables.create()
		    })
		        .subscribe(
		            onNext: { print($0) },
		            onError: { print($0) },
		            onCompleted: { print("Completed") },
		            onDisposed: { print("Disposed") }
		    ).disposed(by: disposeBag)
		}
		
		/* Prints:
		 1
		 anError
		 Disposed
		*/
		```
	* 만약 `.completed`나 `.error` 이벤트 모두 방출하지 않고 disposeBag 에 어떠한 구독도 추가하지 않는다면 어떻게 될까? (주석 5, 2와 가장 마지막 `.disposed(by: disposeBag)`를 주석처리 또는 지워보자)
		* 두 개의 `onNext`	요소인 `1`과 `?`가 모두 찍힐 것이다. 
        * 하지만 종료를 위한 이벤트도 방출하지 않고 `.disposed(by: disposeBag)` 도 하지 않기 때문에 결과적으로 메모리 낭비가 발생하게 될 것이다.
	
## G. observable factory 만들기
* subscriber를 기다리는 (날 시동시켜줘!) Observable을 만드는 대신, 각 subscriber에게 새롭게 Observable 항목을 제공하는 Obaservable factory를 만드는 방법도 있다. 
* 하기의 코드를 살펴보자
	```swift
	example(of: "deferred") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    var flip = false
	    
	    // 2
	    let factory: Observable<Int> = Observable.deferred{
	        
	        // 3
	        flip = !flip
	        
	        // 4
	        if flip {
	            return Observable.of(1,2,3)
	        } else {
	            return Observable.of(4,5,6)
	        }
	    }
	    
	    for _ in 0...3 {
	        factory.subscribe(onNext: {
	            print($0, terminator: "")
	        })
	            .disposed(by: disposeBag)
	        
	        print()
	    }
	}
	/* Prints:
	123
	456
	123
	456
	*/
	```
	
	* 주석대로 하나씩 살펴보면,
		* 1) Observable이 리턴할 `Bool`값을 생성한다.
		* 2) `deferred` 연산자를 이용해서 `Int` factory Observable을 생성한다.
		* 3) `factory`가 구독할 `flip`을 전환한다 (false > true) 
		* 4) `flip`의 값에 따라 다른 Observable을 리턴하도록 한다.
	* 이 후 해당 `factory`의 구독을 4번 반복한 값을 출력해볼 수 있다. 
		* `factory`를 구독할 때마다, 두개의 Observable이 번갈아가며 출력된다. 
	* 두호님 Tip: factory라는 건 이 책에서 만든 개념같은 거예요. `.deferred` 라는 놈은 Observable을 리턴하는 메소드입니다. Swift 기본 문법에서 `lazy var` 같은 느낌처럼, subscribe 될 때, `.deferred`가 실행되어 리턴 값인 Observable이 나오게 됩니다.

## H. Traits 사용
* Trait은 일반적인 Observable 보다 좁은 범위의 Observable 으로 선택적으로 사용할 수 있다. 
* Trait을 사용해서 코드 가독성을 높일 수 있다. 

### 1. 종류
* `Single`, `Maybe`, `Completable`라는 세 가지 Trait이 있다.

#### Single
* `.success(value)` 또는 `.error` 이벤트를 방출한다.
* `.success(value)` = `.next` + `.completed`
* 사용: 성공 또는 실패로 확인될 수 있는 1회성 프로세스 (예. 데이터 다운로드, 디스크에서 데이터 로딩)

#### Completable
* `.completed` 또는 `.error` 만을 방출하며, 이 외 어떠한 값도 방출하지 않는다.
* 사용: 연산이 제대로 완료되었는지만 확인하고 싶을 때 (예. 파일 쓰기)

#### Maybe
* `Single`과 `Completable`을 섞어놓은 것
* `success(value)`, `.completed`, `.error`를 모두 방출할 수 있다.
* 사용: 프로세스가 성공, 실패 여부와 더불어 출력된 값도 내뱉을 수 있을 때
* 자세한 내용은 Ch4. 부터 더 접할 수 있으며 지금은 아주 간단한 예제로만 확인하자
	* `single`을 이용해서 `Resources` 폴더 내의 `Copyright.txt` 파일의 일부 텍스트를 읽어야 한다고 가정해보자.

		```swift
		example(of: "Single") {
		    
		    // 1
		    let disposeBag = DisposeBag()
		    
		    // 2
		    enum FileReadError: Error {
		        case fileNotFound, unreadable, encodingFailed
		    }
		    
		    // 3
		    func loadText(from name: String) -> Single<String> {
		        // 4
		        return Single.create{ single in
		            // 4 - 1
		            let disposable = Disposables.create()
		            
		            // 4 - 2
		            guard let path = Bundle.main.path(forResource: name, ofType: "txt") else {
		                single(.error(FileReadError.fileNotFound))
		                return disposable
		            }
		            
		            // 4 - 3
		            guard let data = FileManager.default.contents(atPath: path) else {
		                single(.error(FileReadError.unreadable))
		                return disposable
		            }
		            
		            // 4 - 4
		            guard let contents = String(data: data, encoding: .utf8) else {
		                single(.error(FileReadError.encodingFailed))
		                return disposable
		            }
		            
		            // 4 - 5
		            single(.success(contents))
		            return disposable
		        }
		    }
		}
		```
		
		* 주석대로 하나씩 살펴보면, 
			* 1) 이따가 쓸 dispose bag을 생성
			* 2) 디스크의 데이터를 읽으면서 발생할 수 있는 에러를 `Error` enum을 통해 정의함
			* 3) 디스크의 파일로부터 텍스트를 불러와서 `single`을 리턴하는 함수를 생성
			* 4) `single`을 생성하고 리턴함
		* 주석 4의 create 클로저를 살펴보면,
			* 4-1) `create` method의 `subscribe` 클로저는 반드시 disposable을 리턴해야하므로, 리턴할 값을 생성
			* 4-2) 파일명에 대한 경로를 받아오고, 만약에 해당 파일이 없으면 `single`에 해당 에러를 추가하고 disposable을 리턴한다.
			* 4-3) 해당 파일로부터 데이터를 받아오고, 파일을 읽을 수 없다면 역시 같은 방식으로 처리
			* 4-4) 파일 내 콘텐츠를 String으로 인코딩했을 때 에러가 없는지 검사
		
		* 아래와 같이 함수를 실행시켜볼 수 있다.
		
			```swift
			 loadText(from: "Copyright")
			        .subscribe{
			            switch $0 {
			            case .success(let string):
			                print(string)
			            case .error(let error):
			                print(error)
			            }
			        }
			        .disposed(by: disposeBag)
			```
		* 파일명을 변경하는 등 여러 변화를 줘서 에러를 발생시켜보자.

## Challenges
### 1. 부수작용 구현해보기 (do 연산자)
* 앞서 예로든 `never` 연산자는 아무것도 출력하지 않는다. 당시에는 해당 observable을 구독하기 전에 dispose bag에 넣어버렸지만, 만약 그 전에 어떤 값을 추가했다면 `subscribe`의 `onDisposed` 핸들러를 통해 여전히 메시지를 출력할 수 없다. 
* 이 같은 상황에서, 작업중인 Observable에 영향을 주지 않고 별도의 작업을 수행할 수 있는 유용한 연산자가 있다.
* `do` 연산자는 부수작용을 추가하는 것을 허용한다. 다시 말하면 어떤 작업을 추가해도 방출하는 이벤트는 변화시키지 않는 것이다. 
* `do`는 이벤트를 다음 연산자로 그냥 통과시켜버린다.
* `do`는 `subscribe`는 가지고 있지 않는 `onSubscribe` 핸들러를 가지고 있다. 
* `do` 연산자를 이용할 수 있는 method는 `do(onNext:onError:onCompleted:onSubscribe:onDispose)`로, 이 중 어떤 이벤트에 대해서든 핸들러를 제공할 수 있다. 

> Q. 앞선 `never` 예제에 `do` 연산자의 `onSubscribe` 핸들러를 이용해서 프린트 해 볼 것. dispose bag을 subscription에 추가하도록 할 것.
 
* A. 

	```swift
	example(of: "never") {
	    let observable = Observable<Any>.never()
	    
	    // 1. 문제에서 요구한 dispose bag 생성
	    let disposeBag = DisposeBag()
	    
	    // 2. 그냥 뚫고 지나간다는 do의 onSubscribe 에다가 구독했음을 표시하는 문구를 프린트하도록 함
	    observable.do(
	        onSubscribe: { print("Subscribed")}
	        ).subscribe(					// 3. 그리고 subscribe 함
	            onNext: { (element) in
	                print(element)
	        },
	            onCompleted: {
	                print("Completed")
	        }
	    )
	    .disposed(by: disposeBag)			// 4. 앞서 만든 쓰레기봉지에 버려줌
	}
	```

### 2. 디버그 정보 찍어보기 (debug 연산자)
* 1번 문제는 구현한 Rx 코드를 이용해 디버그 할 수 있는 방법 중 하나지만, 디버그가 목적이라면 더 나은 방법이 있다.
* `debug` 연산자는 observable의 모든 이벤트를 프린트 함
* 여러가지 파라미터가 있겠지만 가장 효과적인 것은 특정 문자열을 `debug` 연산자에 넣어주는 것 (예. debug("어떤 문자"))

> Q. 1번 문제를 `debug` 연산자를 통해 프린트 해 볼 것.

* A.

```swift
example(of: "never") {
    let observable = Observable<Any>.never()
    let disposeBag = DisposeBag()			// 1. 역시 dispose bag 생성
    
    observable
    	.debug("never 확인")			// 2. 디버그 하고
    	.subscribe()					// 3. 구독 하고
    	.disposed(by: disposeBag) 	// 4. 쓰레기봉지에 쏙
}

/* Prints:
2018-01-09 18:00:24.752: never 확인 -> subscribed
2018-01-09 18:00:24.754: never 확인 -> isDisposed
*/
```

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
