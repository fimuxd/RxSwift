# Ch.5 Filtering Operators

## A. Getting Started

* 여기서 배울 것은 filtering operator로, 이 것을 통해 `.next`이벤트를 통해 받아오는 값을 선택적으로 취할 수 있다.
* 기존 Swift에서 `filter(_:)`를 사용해봤다면 이해하기 쉬울 것이다. 

## B. Ignoring operators

### 1. .ignoreElements()

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/1.ignoreElements.png?raw=true" height = 150>

* `ignoreElements`는 `.next` 이벤트를 무시한다. `completed`나 `.error` 같은 정지 이벤트는 허용한다. [Marble diagram 참고](http://rxmarbles.com/#ignoreElements)
* 다음과 같은 ~야구게임~ 코드를 확인해보자

	```swift
	example(of: "ignoreElements") {
	    
	    // 1
	    let strikes = PublishSubject<String>()
	    let disposeBag = DisposeBag()
	    
	    // 2
	    strikes
	        .ignoreElements()
	        .subscribe({ _ in
	            print("You're out!")
	        })
	        .disposed(by: disposeBag)
	    
	    // 3
	    strikes.onNext("X")
	    strikes.onNext("X")
	    strikes.onNext("X")
	    
	    // 4
	    strikes.onCompleted()
	}
	```
	
	* 주석을 따라 확인해보자
		* 1) `String` 값을 뱉는 `PublishSubject`와 `DisposeBag`을 만든다
		* 2) `strikes` subject를 구독한다. 단 구독전에 `.ignoreElements()`를 넣는다. 아직은 아무것도 프린트 되지 않는다. 
		* 3) `onNext()` 이벤트를 추가한다. 여전히 아무일도 일어나지 않는다.
		* 4) `strikes`를 `onCompleted()`한다. 콘솔에 `You're out!`이 찍힌다.

### 2. .elementAt

* 야구에서처럼 세 번째 스트라이크와 같이, Observable에서 방출된 n번째 요소만 처리하려는 경우가 있을 수 있다. 이 때 `elementAt()`을 쓸 수 있다. 이 것은 받고싶은 요소에 해당하는 index만을 방출하고 나머지는 무시한다. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/2.%20elementAt.png?raw=true" height = 150> 

* 다음의 코드를 보자.

	```swift
	example(of: "elementAt") {
	    
	    // 1
	    let strikes = PublishSubject<String>()
	    let disposeBag = DisposeBag()
	    
	    // 2
	    strikes
	        .elementAt(2)
	        .subscribe(onNext: { _ in
	            print("You're out!")
	        })
	        .disposed(by: disposeBag)
	    
	    // 3
	    strikes.onNext("X")
	    strikes.onNext("X")
	    strikes.onNext("X")
	}
	```
	
	* 주석을 따라 보면
		* 1) PublishSubject와 DisposeBag을 만든다.
		* 2) Publish Subject를 구독하는데, 이번에는 `.elementAt(2)`를 추가한다. 2번째 인덱스, 즉, 3 번째 값을 뱉을 것이다.
		* 3) `.completed`나 `.error`가 아닌데도 콘솔에 "You're out!"이 출력된다.

### 3. .filter

* `ignoreElements`와 `elementAt`은 observable의 요소들을 필터링하여 방출한다. 
* `filter`는 필터링 요구사항이 한 가지 이상일 때 사용할 수 있다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/3.filter.png?raw=true" height = 150>

	* 그림에서 `filter`를 거치면 `1`, `2`만 필터된다. 왜냐하면 `filter`에서 3보다 작은 요소만 출력하라고 선언했기 때문이다.

* 하기의 코드를 살펴보자.

	```swift
	example(of: "filter") {
	    
	    let disposeBag = DisposeBag()
	    
	    // 1
	    Observable.of(1,2,3,4,5,6)
	        // 2
	        .filter({ (int) -> Bool in
	            int % 2 == 0
	        })
	        // 3
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	}
	```
	
	* 주석을 따라 하나씩 살펴보면,
		* 1) `Int`를 받는 observable을 만든다.
		* 2) `filter`를 사용하여 홀수를 제외하는 로직을 작성한다. `filter`는 각각의 요소들을 확인하여 `true`인 요소들만 출력하고 그렇지 않은 아이들은 무시한다.
		* 3) 구독하여 방출된 아이들을 프린트 하도록 한다. `2 4 6`이 프린트 된다.


## C. Skipping operators

### 1. .skip

*  확실히 몇개의 요소를 skip 하고 싶을 수 있다.
* `skip` 연산자는 첫 번째 요소부터 n개의 요소를 skip하게 해준다. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/4.%20skip.png?raw=true" height = 150>

	* 그림을 보면 `skip()` 연산자를 통해 처음 2개의 요소가 skip되는 것을 알 수 있다.
* 다음 코드를 확인해보자.

	```swift
	example(of: "skip") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    Observable.of("A", "B", "C", "D", "E", "F")
	        // 2
	        .skip(3)
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	}
	```
	
	* 주석을 따라 확인해보면,
		* 1) `String`의 Observable을 만든다.
		* 2) 3번째까지의 요소를 skip하도록 하고, 구독한다. 
		* 처음 세개 요소인 `A`, `B`, `C`는 skip되고 뒤의 `D`, `E`, `F` 가 출력된다.

### 2. skipWhile

* 구독하는 동안 모든 요소를 필터링하는 `filter`와는 달리, `.skipWhile`은 어떤 요소를 skip하지 않을 때까지 skip하고 종료하는 연산자이다.
* `skipwWhile`은 skip할 로직을 구성하고 해당 로직이 `false` 되었을 때 방출한다. `filter`와 반대다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/5.skipWhile.png?raw=true" height = 150>

	* 그림을 보면, `1`은 무시된다. 왜냐하면 `skipWhile`문 내부에서 `true` 이기 때문. 
	* `2`는 방출된다. 왜냐하면 `false` 이므로
	* `3`도 방출된다. 왜? `true`인데? 왜냐하면 `skipWhile`이 더이상 skip 하지 않기 때문. `1`을 한번 skip 했으므로 작동하지 않는 것이다.
* 다음 코드를 확인해보자

	```swift
	example(of: "skipWhile") {
	    
	    let disposeBag = DisposeBag()
	    
	    // 1
	    Observable.of(2, 2, 3, 4, 4)
	        //2
	        .skipWhile({ (int) -> Bool in
	            int % 2 == 0
	        })
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	}
	``` 
	
	* 주석을 따라가보자
		* 1) Observable을 생성한다
		* 2) 홀수인 요소가 나올 때까지 skip하기 위해 `skipWhile` 을 사용한다.
	* 프린팅된 값은 `3 4 4`
* 보험금 청구 앱을 개발한다고 가정해보자. 공제액이 충족될 때까지 보험금 지급을 거부하기 위해 `skipWhile`을 사용할 수 있다. 

### 3. skipUntil

* 지금까지의 필터링은 고정 조건에서 이루어졌다. 만약에 다른 observable에 기반한 요소들을 다이나믹하게 필터하고 싶다면 어떻게 해야할까?

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/6.skipUntil.png?raw=true" height = 200>

* `skipUnitl`은 다른 observable이 시동할 때까지 현재 observable에서 방출하는 이벤트를 skip 한다.
* `skipUnitl`은 다른 observable이 `.next`이벤트를 방출하기 전까지는 기존 observable에서 방출하는 이벤트들을 무시하는 것이다. 
* 다음과 같은 코드를 확인해보자

	```swift
	example(of: "skipUntil") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    let subject = PublishSubject<String>()
	    let trigger = PublishSubject<String>()
	    
	    // 2
	    subject
	        .skipUntil(trigger)
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	    
	    // 3
	    subject.onNext("A")
	    subject.onNext("B")
	    
	    // 4
	    trigger.onNext("X")
	    
	    // 5
	    subject.onNext("C")
	}
	```
	
	* 주석을 따라 확인해보면, 
		* 1) `subject`와 `trigger`라는 PublishSubject를 만든다. 
		* 2) `subject`를 구독하는데 그 전에 `.skipUnitl`을 통해 `trigger`를 추가한다.
		* 3) `subject`에 `.onNext()`로 `A`, `B` 추가한다.
		* 4) `trigger`에 `.onNext()`로 `X`를 추가한다.
		* 5) `subject`에 새로운 이벤트`C`를 추가한다. 그제서야 `C`가 방출되는 것을 콘솔에서 확인할 수 있다. 왜냐하면 그 전까지는 `.skipUnitl`이 막고 있었기 때문이다 

## D. Taking operators

### 1. take

* Taking은 skipping의 반대 개념이다.
* RxSwift에서 어떤 요소를 취하고 싶을 때 사용할 수 있는 연산자는 `take`다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/7.take.png?raw=true" height = 150>
	
	* 그림을 보면 `take()`를 통해, 처음 2개의 값을 취한 것을 알 수 있다.
* 다음 코드를 생각해보자

	```swift
	example(of: "take") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    Observable.of(1,2,3,4,5,6)
	        // 2
	        .take(3)
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	}
	``` 
	
	* 이렇게하면 처음부터 세번째 값까지인 `1 2 3`이 출력된다.

### 2. takeWhile
* `takeWhile`은 `skipWhile`처럼 작동한다. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/8.takeWhile.png?raw=true" height = 150>
	
	* 그림과 같이 `takeWhile` 구문 내에 설정한 로직에서 `true`에 해당하는 값을 방출하게 된다.

### 3. enumerated

* 방출된 요소의 index를 참고하고 싶은 경우가 있을 것이다. 이럴 때는 `enumerated` 연산자를 확인할 수 있다.
* 기존 Swift의 `enumerated` 메소드와 유사하게, Observable에서 나오는 각 요소의 index와 값을 포함하는 튜플을 생성하게 된다.
* 하기의 코드를 확인해보자.

	```swift
	example(of: "takeWhile") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    Observable.of(2,2,4,4,6,6)
	        // 2
	        .enumerated()
	        // 3
	        .takeWhile({ index, value in
	            // 4
	            value % 2 == 0 && index < 3
	        })
	        // 5
	        .map { $0.element }
	        // 6
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	}
	```
	
	* 주석을 따라 확인해보면
		* 1) observable을 만든다
		* 2) `.enumerated`를 이용하여 index와 값을 가지는 튜플을 받아낸다
		* 3) `.takeWhile`을 이용하여, 튜플 각각의 요소들을 확인한다. 
		* 4) 짝수이면서 index가 3 미만인 요소를 취하는 로직을 작성한다.
		* 5) `.map`을 통해 추출한 튜플중에 값만 취하게 한다.
		* 6) 구독한 값을 찍습니다.
	* 해당 값인 `2 2 4`가 프린트 됩니다.

### 4. takeUntil

* `skipUntil`처럼 `takeUntil`도 있다. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/9.takeUntil.png?raw=true" height = 200>

	* 그림과 같이, trigger가 되는 Observable이 구독되기 전까지의 이벤트값만 받는 것이다.
* 아래의 코드를 살펴보자.

	```swift
	example(of: "takeUntil") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    let subject = PublishSubject<String>()
	    let trigger = PublishSubject<String>()
	    
	    // 2
	    subject
	        .takeUntil(trigger)
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	    
	    // 3
	    subject.onNext("1")
	    subject.onNext("2")
	    
	    // 4
	    trigger.onNext("X")
	    
	    // 5
	    subject.onNext("3")
	}
	```  

	* 주석을 따라 확인해보자.
		* 1) `subject`와 `trigger` 라는 `PublishSubject<String>`을 각각 만든다.
		* 2) `takeUntil()` 메소드를 통해 trigger를 연결해주고 구독한다.
		* 3) `subject`에 `1`, `2`를 `onNext`를 통해 추가한다. (각각 프린트 된다)
		* 4) `trigger`에 `onNext` 이벤트를 추가한다. 이걸 통해서 `subject`에서 값을 취하는 게 멈출 것이다.
		* 5) `subject`에 새로운 값`3`을 `onNext` 이벤트로 추가한다. (`3`은 프린트 안되쥬)
* ~이 책 마지막에서 배울~ RxCocoa 라이브러리의 API를 사용하면 dispose bag에 dispose를 추가하는 방식 대신 `takeUntil`을 통해 구독을 dispose 할 수 있다. 아래의 코드를 살펴보자.

	```swift
	someObservable
		.takeUntil(self.rx.deallocated)
		.subscribe(onNext: {
			print($0)
		})
	```
	
	* 이전의 코드에서는 `takeUntil`의 `trigger`로 인해서 `subject`의 값을 취하는 것을 멈췄었다. 
	* 여기서는 그 trigger 역할을 `self의 할당해제`가 맡게 된다. 보통 `self`는 아마 뷰컨트롤러나 뷰모델이 될것이다. 
	
## E. Distinct operators

* 여기서 배울 것은 중복해서 이어지는 값을 막아주는 연산자이다.

### 1. distinctUntilChanged

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/10.distincUntilChanged.png?raw=true" height = 150>

	* 그림에서처럼 `distinctUntilChanged`는 연달아 같은 값이 이어질 때 중복된 값을 막아주는 역할을 한다.
	* `2`는 연달아 두 번 반복되었으므로 뒤에 나온 `2`가 배출되지 않았다.
	* `1`은 중복이긴 하지만 연달아 반복된 것이 아니므로 그대로 배출된다.
* 아래 코드를 살펴봅시다.

	```swift
	example(of: "distincUntilChanged") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    Observable.of("A", "A", "B", "B", "A")
	        //2
	        .distinctUntilChanged()
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	}
	```

	* 주석을 따라 살펴봅시다.
		* 1) `String`을 받는 observable을 만든다
		* 2) `distinctUntilChanged`를 입력하고 구독합니다.
	* 연달아 중복되는 index 1,3의 `A`,`B`가 무시되고 `A B A`가 프린트 된다.

### 2. distinctUntilChanged(_:)

* `distinctUntilChanged`는 기본적으로 구현된 로직에 따라 같음을 확인한다. 그러나 커스텀한 비교로직을 구현하고 싶다면 `distinctUntilChanged(_:)`를 사용할 수 있다. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/11.distincUntilChanged().png?raw=true" height = 200>

	* 그림은 `value`라 명명된 값을 서로 비교하여 중복되는 값을 제외하고 있다.
* 아래의 코드를 살펴보자.

	```swift
	example(of: "distinctUntilChanged(_:)") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    let formatter = NumberFormatter()
	    formatter.numberStyle = .spellOut
	    
	    // 2
	    Observable<NSNumber>.of(10, 110, 20, 200, 210, 310)
	        // 3
	        .distinctUntilChanged({ a, b in
	            //4
	            guard let aWords = formatter.string(from: a)?.components(separatedBy: " "),
	                let bWords = formatter.string(from: b)?.components(separatedBy: " ") else {return false}
	            
	            var containsMatch = false
	            
	            // 5
	            for aWord in aWords {
	                for bWord in bWords {
	                    if aWord == bWord {
	                        containsMatch = true
	                        break
	                    }
	                }
	            }
	            
	            return containsMatch
	        })
	        // 6
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	}
	```
	
	* 주석을 따라 확인해보자.
		* 1) 각각의 번호를 배출해내는 `NumberFormatter()`를 만들어낸다.
		* 2) `NSNumbers` Observable을 만든다. 이렇게 하면 `formatter`를 사용할 때 Int를 변환할 필요가 없다.
		* 3) `distinctUntilChanged(_:)`는 각각의 seuquence 쌍을 받는 클로저다.
		* 4) `guard`문을 통해 값들의 구성요소를 빈 칸 구분하여 조건부로 바인딩하고 그렇지 않으면 `false`를 반환한다. 
		* 5) 중첩 `for-in` 반복문을 통해서 각 쌍의 단어를 반복하고, 검사결과를 반환하여, 두 요소가 동일한 단어를 포함하는지 확인한다.
		* 6) 구독하고 출력한다.
	* 결과는, 다른 요소를 포함하는 요소는 제외된 결과만 출력된다. `10 20 200`
	* a, b, c를 비교해가면서 만약 b가 a와 중첩되는 부분이 있어 prevent 되면, 다음엔 b와 c를 비교하는 것이 아니라 a와 b를 비교하게 됩니다.

## F. Challenges

### 전화번호 만들기

* 1. `skipWhile`을 사용: 전화번호는 0으로 시작할 수 없습니다. 
* 2. `filter`를 사용: 각각의 전화번호는 한자리의 숫자 (10보다 작은 숫자)여야 합니다. 
* 3. `take`와 `toArray`를 사용하여, 10개의 숫자만 받도록 하세요. (미국 전화번호처럼)

> A.
> 
> ```swift
>   input
>     .skipWhile({ (number) -> Bool in
>         number == 0
>     })
>     .filter({ (number) -> Bool in
>         number < 10
>     })
>     .take(10)
>     .toArray()
>     .subscribe(onNext: {
>         let phone = phoneNumber(from: $0)
>         
>         if let contact = contacts[phone] {
>             print("Dialing \(contact) (\(phone))...")
>         } else {
>             print("Contact not found")
>         }
>     })
>     .disposed(by: disposeBag)
> ```
> 
> 콘솔 프린트 -> Contact not found

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com