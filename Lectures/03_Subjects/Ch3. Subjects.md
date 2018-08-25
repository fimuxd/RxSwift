# Ch.3 Subjects

* Ch2. Observable을 통해서 배운건 Observable이 무엇인지, 어떻게 만들고, 구독하고, dispose 하는지였다.
* 하지만 보통의 앱개발에서 필요한 것은 **실시간**으로 Observable에 새로운 값을 **수동으로 추가**하고 subscriber에게 방출하는 것
* 다시 말하면, *Observable*이자 *Observer*인 녀석이 필요하다. 이 것을 **Subject**라고 부른다.

## A. 시작하기

* 다음의 코드를 확인해보자

	```swift
	example(of: "PublishSubject") {

		// 1
	    let subject = PublishSubject<String>()

	    // 2
	    subject.onNext("Is anyone listening?")

	    // 3
	    let subscriptionOne = subject
	        .subscribe(onNext: { (string) in
	            print(string)
	        })

	    // 4
	    subject.on(.next("1"))		//Print: 1

	    // 5
	    subject.onNext("2")		//Print: 2
	}
	```

	* 주석을 따라 확인해보자
		* 1) `PublishSubject`를 만들었다.
			* 이름에서 추측할 수 있듯이, 이 녀석은 뉴스배포자처럼 받은 정보를 가능하면 먼저 수정한 다음에 subscriber에게 배포한다.
			* 여기서는 그 정보가 `String` 타입이다. 따라서 받는 정보, 배포하는 정보 모두 `String` 형태가 된다.
		* 2) 이렇게 추가를 해도 아무 것도 프린트 되지 않는다.
		* 3) 그래서 subscribe을 해보았다. 그런데도 역시 되지 않는다. 왜 그럴까?
			* `PublishSubject`는 *현재*(current)의 subscriber에만 이벤트를 방출한다. 따라서 어떤 정보가 추가되었을 때 구독하지 않았다면 그 값을 얻을 수 없다.
		* 4) 이렇게하면 `1`이 찍힌다.
			* 여기서 확인할 것은, 애초에 subject를 `String` 타입으로 선언했기 때문에 `next`이벤트 내의 값은 `String` 타입이어야만 한다.
			* `subscribe` 연산자와 비슷하게, `.on(.next(_:))`는 새로운 `.next` 이벤트를 subject에 삽입하고, 이벤트 내의 값들을 파라미터로 통과시킨다.
		* 5) `subscribe`처럼 축약형이 있다.
		* `.on(.next(_:))`와 `.onNext(_:)`는 똑같은 것이다. 다만 후자가 좀 더 보기 편하다는 것 뿐.

## B. Subject의 종류
* Subject = Observable + Observer (와 같이 행동한다)
* Subject는 `.next` 이벤트를 받고, 이런 이벤트를 수신할 때마다 subscriber에 방출한다.
* RxSwift에는 4 가지 타입의 subject가 있다.
	* [PublishSubject](https://github.com/fimuxd/RxSwift/blob/master/Lectures/03_Subjects/Ch3.%20Subjects.md#c-publishsubjects로-작업하기): 빈 상태로 시작하여 새로운 값만을 subscriber에 방출한다.
	* [BehaviorSubject](https://github.com/fimuxd/RxSwift/blob/master/Lectures/03_Subjects/Ch3.%20Subjects.md#d-behaviorsubjects로-작업하기): 하나의 초기값을 가진 상태로 시작하여, 새로운 subscriber에게 초기값 또는 최신값을 방출한다.
	* [ReplaySubject](https://github.com/fimuxd/RxSwift/blob/master/Lectures/03_Subjects/Ch3.%20Subjects.md#e-replaysubjects로-작업하기): 버퍼를 두고 초기화하며, 버퍼 사이즈 만큼의 값들을 유지하면서 새로운 subscriber에게 방출한다.
	* [Variable](https://github.com/fimuxd/RxSwift/blob/master/Lectures/03_Subjects/Ch3.%20Subjects.md#f-variables로-작업하기): `BehaviorSubject`를 래핑하고, 현재의 값을 상태로 보존한다. 가장 최신/초기 값만을 새로운 subscriber에게 방출한다.

## C. PublishSubjects로 작업하기
### 1. 개념

* PublishSubject는 구독된 순간 새로운 이벤트 수신을 알리고 싶을 때 용이하다.
* 이런 활동은 구독을 멈추거나, `.completed`, `.error` 이벤트를 통해 Subject가 완전 종료될 때까지 지속된다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/03_Subjects/1.%20publishsubject.png?raw=true" height = 200>

	* 상기 그림의 첫 번째 줄은 subject를 배포한 것이다. 두 번째 줄과 세 번째 줄이 subscriber 들이다.
	* 아래로 향하는 화살표들은 이벤트의 방출, 위로 향하는 화살표들은 구독을 선언하는 것을 의미한다.
	* 첫 번째 subscriber(둘째줄)는 `1` 다음에 구독한다. 따라서 `1` 이벤트는 받지 못하고 `2`,`3`을 받는다.
	* 두 번째 subscriber(셋째줄)는 같은 원리로 `3` 만 받는다.  

* 이를 상기의 코드에 추가해서 표현해보면,

	```swift
	example(of: "PublishSubject") {
	    let subject = PublishSubject<String>()
	    subject.onNext("Is anyone listening?")

	    let subscriptionOne = subject
	        .subscribe(onNext: { (string) in
	            print(string)
	        })
	    subject.on(.next("1"))
	    subject.onNext("2")

	    // 1
	    let subscriptionTwo = subject
	        .subscribe({ (event) in
	            print("2)", event.element ?? event)
	        })

	    // 2
	    subject.onNext("3")

	    // 3
	    subscriptionOne.dispose()
	    subject.onNext("4")

	    // 4
	    subject.onCompleted()

	    // 5
	    subject.onNext("5")

	    // 6
	    subscriptionTwo.dispose()

	    let disposeBag = DisposeBag()

	    // 7
	    subject
	        .subscribe {
	            print("3)", $0.element ?? $0)
	    }
	        .disposed(by: disposeBag)

	    subject.onNext("?")
	}
	```

	* 주석을 따라 하나씩 살펴보자,
		* 1) 두 번째 subscriber를 추가한다. 이벤트들은 옵셔널 값을 가지고 있으며, 이런 옵셔널 값들이 `.onNext` 이벤트와 방출되기 때문에 nil 확인을 해줘야한다. 여기서는 만약 값이 nil이라면 이벤트만 프린트되도록 했다.
		* 2) subject에 `3`을 추가한다. 이렇게 하면 `3`이 `subscriberOne`과 `subscriberTwo`에 의해 두번 출력된다.
		* 3) `subscriptionOne`을 dispose해버리고 subject에 `4`를 추가한다. 이렇게 하면 `subscriberTwo`가 받은 값 (`2) 3` `2) 4`)만 출력된다.
		* 4) ~ 7): subject 자체가 `.completed` 또는 `.error` 이벤트 같은 완전종료 이벤트들을 받으면, 새로운 subscriber에게 더이상 `.next`이벤트를 방출하지 않을 것으로 예상할 수 있다. 하지만 subject는 이러한 **종료 이벤트들을** 이후 새subscriber들에게 **재방출**한다.  
			* subject가 완전종료된 후 새로운 subscriber가 생긴다고 다시 subject가 작동하진 않는다.
			* 다만, `.completed` 이벤트만 방출한다.

* subject가 종료되었을 때에 존재하는 구독자에게만 종료 이벤트를 줄 뿐만 아니라 그 이후에 구독한 subscriber에게도 종료 이벤트를 알려주는 특성이 있다.

### 2. 어떨 때 쓸 수 있을까?

* 시간에 민감한 데이터를 모델링할 때. (예. 실시간 경매 앱)
* (10:00 am이 경매시간이라고 가정하고,) 10:01am에 들어온 유저에게, 9:59am에 기존의 유저에게 날렸던 알람 "서두르세요. 경매가 1분 남았습니다." 을 계속 보내는 것은 아주 무의미하다.  

## D. BehaviorSubjects로 작업하기

### 1. 개념

* `BehaviorSubject`는 마지막 `.next` 이벤트를 새로운 구독자에게 반복한다는 점만 빼면 `PublishSubject`와 유사하다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/03_Subjects/2.%20behaviorsubject.png?raw=true" height = 200>

	* 위 그림에서 첫 번째 줄이 subject 이며, 두 번째와 세 번째 줄이 각각의 subscriber 들이다.
	* 첫 번째 이벤트가 발생한 후 첫 번째 구독자가 구독을 시작했지만 `PublishSubject`와는 다르게 직전의 값`1`을 받는다.
	* 두 번째 이벤트가 발생한 후 두 번째 구독자가 구독을 시작했지만 역시 직전의 값`2`을 받는다.
* 코드를 통해 살펴보자.

	```swift
	// 1
	enum MyError: Error {
	    case anError
	}

	// 2
	func print<T: CustomStringConvertible>(label: String, event: Event<T>) {
	    print(label, event.element ?? event.error ?? event)
	}

	//3
	example(of: "BehaviorSubject") {

	    // 4
	    let subject = BehaviorSubject(value: "Initial value")
	    let disposeBag = DisposeBag()
	}
	```

	* 주석을 따라 확인해보자
		* 1) 발생할 수 있는 에러를 `Error` `enum`으로 만들었다.
		* 2) Generic 문법을 이용하여, 이벤트 내에 값이 있으면 값을 프린트하고, 에러가 있으면 에러를, `nil`이면 이벤트만을 출력할 수 있는 print 메소드를 만들었다. (똘이네👍🏻)
		* 3) `BehaviorSubject`를 초기값을 입력하여 만든다.
			* `BehaviorSubject`는 *항상* 최신의 값을 방출하기 때문에 초기값 없이는 만들 수 없다. 반드시 **초기값** 있어야 한다.
			* 만약 초기값(default값)을 줄 수 없다면 `PublishSubject`를 써야한다.

* 상기 코드에 하단의 코드들을 추가해보자.

	```swift
	    // 6
	    subject.onNext("X")

	    // 5
	    subject
	        .subscribe{
	            print(label: "1)", event: $0)
	        }
	        .disposed(by: disposeBag)

	    // 7
	    subject.onError(MyError.anError)

	    // 8
	    subject
	        .subscribe {
	            print(label: "2)", event: $0)
	        }
	        .disposed(by: disposeBag)
	}
	```

	* 5) 생성한 subject를 구독하고 dispose 시킨다. 이렇게 하면 print 값은 `1) Initial Value` 가 나온다.
	* 6) 입력한 주석 5 코드 상단에 subject에 `"X"`를 가진 `.onNext(_:)` 메소드를 추가한다. 그렇게하면 subject를 구독하기 전 최신값이 `Initial Value`에서 `X`로 바뀌므로 프린트되는 값도 `1) X` 로 변경된다.
	* 7) subject에 `.error` 이벤트를 추가한다.
	* 8) 구독하면 어떻게 나올까? error 이벤트가 한번 찍힐까 두번 찍힐까? 두 개의 구독자에 대해 두번찍히게 된다.

### 2. 어떨 때 쓸 수 있을까?
* `BehaviorSubject`는 뷰를 가장 최신의 데이터로 미리 채우기에 용이하다.
* 예를 들어, 유저 프로필 화면의 컨트롤을 `BehaviorSubject`에 바인드 할 수 있다. 이렇게 하면 앱이 새로운 데이터를 가져오는 동안 최신 값을 사용하여 화면을 미리 채워놓을 수 있다.

## E. ReplaySubjects로 작업하기

### 1. 개념

* `ReplaySubject`는 생성시 선택한 특정 크기까지, 방출하는 최신 요소를 일시적으로 캐시하거나 버퍼한다. 그런 다음에 해당 버퍼를 새 구독자에게 방출한다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/03_Subjects/3.%20replaysubject.png?raw=true" height = 200>

	* 상단의 그림에서 첫 번째 줄이 subject, 아래에 있는 애들이 구독자들이다. 여기서 subject의 버퍼 사이즈는 2다. 첫 번째 구독자(두번째줄)는 subject와 함께 구독하므로 subject의 값들을 그대로 갖는다. 두번째 구독자(세번째줄)은 subject가 두개의 이벤트를 받은 후 구독하였지만 버퍼사이즈`2`만큼의 값을 역시 받을 수 있다.
* **(주의)** `ReplaySubject`를 사용할 때 유념해야할 것이 있다. 바로 이러한 버퍼들은 메모리가 가지고 있다는 것이다.
	* 이미지나 array 같이 메모리를 크게 차지하는 값들을 큰 사이즈의 버퍼로 가지는 것은 메모리에 엄청난 부하를 준다.
* 다음의 코드를 살펴보자

	```swift
	example(of: "ReplaySubject") {

	    // 1
	    let subject = ReplaySubject<String>.create(bufferSize: 2)
	    let disposeBag = DisposeBag()

	    // 2
	    subject.onNext("1")
	    subject.onNext("2")
	    subject.onNext("3")

	    // 3
	    subject
	        .subscribe {
	            print(label: "1)", event: $0)
	        }
	        .disposed(by: disposeBag)

	    subject
	        .subscribe {
	            print(label: "2)", event: $0)
	        }
	        .disposed(by: disposeBag)
	}
	```

	* 주석을 따라 하나씩 살펴보자.
  		* 1) 버퍼 사이즈 2를 가지는 `ReplaySubject`를 만든다. 생성은 `.create(bufferSize:)` 메소드를 이용한다.
  		* 2) `1`, `2`, `3` 세 개의 요소들을 subject에 추가한다.
  		* 3) 해당 subject에 대한 두 개의 구독자를 생성한다.
	* 최근 두개의 요소`2`,`3`은 각각의 구독자에게 보여진다. 값`1`은 방출되지 않는다. 왜냐하면 버퍼사이즈가 2니까.
* 하기 코드를 추가해보자.

	```swift
	subject.onNext("4")

	    subject.subscribe {
	        print(label: "3)", event: $0)
	        }
	        .disposed(by: disposeBag)
	```

	* subject에 추가적으로 `4`를 추가하였고, `3)`으로 표시될 새로운 구독자를 추가했다.
	* 기존 구독자 `1)`,`2)`는 새롭게 subject에 추가된 값인 `4`를 받을 것이고, 새 구독자인 `3)`은 버퍼사이즈`2`개 만큼의 최근 값을 받을 것이다. 즉 최근 값 `3`,`4`를 받게 된다.
* 하기 코드를 `subject.onNext("4")` 하단에 추가해보자.

	```swift
	subject.onError(MyError.anError)

	  /* Prints:
     1) 4
     2) 4
     1) anError
     2) anError
     3) 3
     3) 4
     3) anError
     */
	```

	* subject가 `error`를 통해 완전 종료되었음에도 불구하고 새 구독자`3)`에게 버퍼에 있는 값들을 보내주고 있다.
	* subject가 종료되었어도 버퍼는 여전히 돌아다니고 있기 때문에 이런 결과가 가능하다. 따라서 `error`를 추가한 다음에는 반드시 dispose를 하여 이벤트의 재방출을 막을 수 있다.
* 하기 코드를 `subject.onError(MyError.anError)` 하단에 추가해보자.

	```swift
	subject.dispose()

	/* Prints:
     3) Object `RxSwift.(ReplayMany in _33052C2CE59F358A8740AFDD4371DD39)<Swift.String>` was already disposed.
     */
	```

 	* 이렇게 하면 새로운 구독자는 에러 이벤트만 받을 것이다. 왜냐하면 subject 자체가 구독 전에 이미 dispose 되었으므로.
 	* 다만, `ReplaySubject`에 명시적으로 `dispose()`를 호출하는 것은 적절하지 않다. 왜냐하면 만약 subjuect의 구독을 disposeBag에 넣고, 이 subject의 소유자(보통은 ViewController나 ViewModel)가 할당 해재되면 모든 것들이 dispose 될 것이기 때문이다.
 	* 참고로 상기 에러메시지에 표시된 `ReplayMany`는 `ReplaySubject`를 생성할 때 사용되는 내부 유형이다.

### 2. 어떨 때 쓸 수 있을까?

* 만약에 `BehaviorSubject`처럼 최근의 값외에 더 많은 것을 보여주고 싶다면 어떻게 해야할까? 예를 들어 검색창같이, 최근 5개의 검색어를 보여주고 싶을 수 있다. 이럴 때 `ReplaySubject`를 사용할 수 있다.

## F. Variables로 작업하기

* Observable의 *현재값currentValue* 이 궁금할 수 있다.
* 앞서 얘기한 것처럼 `Variable`은 `BehaviorSubject`를 래핑하고, 이들의 현재값을 *상태State* 로 보유한다. 따라서 현재값은 `value` 프로퍼티를 통해서 알 수 있다.
* `value` 프로퍼티를 `Variable`의 새로운 요소로 가지기 위해선 일반적인 subject나 observable과는 다른 방법으로 추가해야한다. 즉 `onNext(_:)`를 쓸 수 없다.
* 다른 `Subject`와 대조되는 `Variable`의 또 다른 특성은, 에러가 발생하지 않을 것임을 **보증**한다는 것이다. 따라서 `.error` 이벤트를 variable에 추가할 수 없다.
* 또한, variable은 할당 해재되었을 때 자동적으로 완료되기 때문에 수동적으로 `.completed`를 할 필요도/할 수도 없다.
* 아래의 코드를 확인해보자

	```swift
	example(of: "Variable") {

	    // 1
	    let variable = Variable("Initial value")
	    let disposeBag = DisposeBag()

	    // 2
	    variable.value = "New initial value"

	    // 3
	    variable.asObservable()
	        .subscribe {
	            print(label: "1)", event: $0)
	        }
	        .disposed(by: disposeBag)

	    /* Prints:
	     1) New initial value
	    */  
	}
	```

	* 주석을 따라 하나씩 살펴보자
		* 1) 초기값을 가지는 variable을 만들자. variable의 타입은 타입유추가 가능하지만 여기서는 `Variable<String>("Initial value")`이라고 명시해주었다.
		* 2) variable에 새 값`New initial value`를 추가한다.
		* 3) variable의 구독을 위해서는 `asObservable()`을 호출하여 variable이 subject처럼 읽힐 수 있도록 한다.
* 아래의 코드를 추가해보자

	```swift
	    // 4
	    variable.value = "1"

	    // 5
	    variable.asObservable()
	        .subscribe {
	            print(label: "2)", event: $0)
	        }
	        .disposed(by: disposeBag)

	    // 6
	    variable.value = "2"

	    /* Prints:
	     1) 1
	     2) 1
	     1) 2
	     2) 2
	    */
	```

	* 주석을 따라 하나씩 살펴보자
		* 4) 새로운 값`1`을 variable에 추가한다
		* 5) variable에 새 구독자`2)`를 추가한다
		* 6) 새로운 값`2`를 variable에 추가한다.  
	* `.error`나 `.completed` 이벤트를 variable에 추가할 방법은 없다. (추가하면 컴파일러 에러남)

### 2. 어떨 때 쓸 수 있을까?

* variable은 유동적이다.
* observable처럼 구독할 수 있고, subject처럼 새로운 `.next`이벤트를 받을 때 마다 반응하도록 구독할 수 있다.
* 업데이트 구독없이 그냥 현재값을 확인하고 싶을 때 일회성으로 적용될 수 있다.
* [두 번째 challenge](https://github.com/fimuxd/RxSwift/blob/master/Lectures/03_Subjects/Ch3.%20Subjects.md#2-variable을-이용하여-유저-세션-상태를-관찰하고-체크하기)를 통해 확인해보자.


## G. Challenges

### 1. PublishSubject를 이용하여 블랙잭 카드딜러 만들기

* `SupportCode.swift`내의 `cardString(for:)`, `point(for:)` 메소드와 `HandError` enum, 제공된 array등을 이용하여 문제를 풀어보자
* `// Add code to update dealtHand here` 주석부분에 `point(for:)`에 `hand` array를 넣어 결과 값을 얻는다. 만약 결과가 `21`보다 크면 `HandError.busted`를 `dealtHand`에 추가한다. 그렇지 않으면 `hand`를 `dealtHand`에 .next` 이벤트로 추가한다.
*  `// Add subscription to dealtHand here` 주석부분에 `dealtHand`와 `.next`, `.error` 이벤트 구독을 구현한다. `.next`이벤트에는 `cardString(for:)`와 `points(for:)`를 호출하여 얻은 `String` 결과를 포함하게 하고, `.error`에는 에러가 프린트 되도록 한다.
* `deal(_:)`에 3을 넣어 호출하므로 playground를 돌릴 때 마다 3개의 카드가 나올 것이다.

#### // Add code to update dealtHand here

```swift
if point(for: hand) > 21 {
	dealtHand.onError(HandError.busted)
} else {
	dealtHand.onNext(hand)
}
```

#### // Add subscription to dealtHand here

```swift
dealtHand
	.subscribe(
		onNext: {
			print(cardString(for: $0), "for", points(for: $0), "points")
		},

		onError: {
			print(String(describing: $0).capitalized)
	})
	.disposed(by: disposeBag)
```

### 2. Variable을 이용하여 유저 세션 상태를 관찰하고 체크하기

* 대부분의 앱들은 유저 세션을 추적하고 있다. variable은 이러한 용도에 적합하다.
* 로그인 또는 로그아웃 같은 유저 세션이 변화할 때마다 반응하도록 구독할 수도 있지만, 그저 일회성으로 현상태만 점검하고 싶을 수 있다.

#### // Create userSession Variable of type UserSession with initial value of .loggedOut

```swift
let userSession = Variable(UserSession.loggedOut)
```

#### // Subscribe to receive next events from userSession

```swift
userSession.asObservable()
        .subscribe{
            print("userSession changed", $0)
        }
        .disposed(by: disposeBag)
```

#### // Update userSession

```swift
userSession.value = UserSession.loggedIn
```

#### // Update userSession

```swift
    func logOut() {
        userSession.value = UserSession.loggedOut
    }
```

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
