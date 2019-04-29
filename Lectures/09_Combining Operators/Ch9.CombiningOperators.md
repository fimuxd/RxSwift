# Ch.9 Combining Operators

## A. 시작하기

* 이전의 chapter에서는, observable sequence를 어떻게 만들고, 필터링하고 변형하는지를 확인해봤다.
* 이 장에서는 다양한 방법으로 sequence들을 모으고, 각각의 sequence내의 데이터들을 병합하는 방법에 대해 배울 것이다.
* RxSwift의 필터링과 변형 연사자들이 Swift의 표준 연산자들과 아주 유사한 것처럼, 여기서도 Swift 표준 라이브러리에서 array를 핸들링할 때 사용했던 몇 개의 유사한 연산자들을 찾을 수 있을 것이다.

## B. 앞에 붙이기

* observable로 작업할 때 가장 중요하게 확인해야 할 것은 observer가 초기값을 받는지 여부이다.

### 1. startWith(_:)

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/1.prefixing.png?raw=true" height = 150>

* 예를 들면 "현재 위치"나 "네트워크 연결 상태" 같이 "현재 상태"가 필요한 상황이 있다. 이럴 때 현재 상태와 함께 초기값을 붙일 수 있다.
* 다음 코드를 확인해보자.

	```swift
	example(of: "startWith") {
	    // 1
	    let numbers = Observable.of(2, 3, 4)

	    // 2
	    let observable = numbers.startWith(1)
	    observable.subscribe(onNext: {
	        print($0)
	    })

	    /* Prints:
	     1
	     2
	     3
	     4
	    */
	}
	```

	* `startWith(_:)`는 observable sequence에 초기값을 앞에 붙일 수 있다. 값은 당연히 기존 observable 요소의 타입과 같아야 한다.
	* 상기 코드를 주석에 따라 살펴보면,
		* 1) 숫자들의 sequence를 만든다.
		* 2) 값 `1`로 시작하는 sequence를 만든다. 그리고 기존의 sequence를 이어붙인다.
* `startWith(_:)`의 위치에 속지 말 것! (기존 시퀀스 뒤에 startWith가 추가되어서 그런가?)
* `startWith`는 RxSwift의 결정론적 성질에 잘 부합한다. 추후에 어떤 업데이트가 있더라도 초기값을 즉시 얻을 수 있는 Observer를 보장한다.

### 2 Observable.concat(_:)

* 사실 `startWith`는 좀 더 일반적인 **`concat`** 연산자 계열의 단순 변형이다.
	* 방금 `startWith` 예제로 구현한 것은 하나의 값을 갖는 sequence를 다른 sequence에 연결한 것이다.
	* `Observable.concat(_:)`을 통해서는 두개의 sequence를 묶을 수 있다.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/2.concat.png?raw=true" height = 200>

* 하기 코드를 살펴보자

	```swift
	example(of: "Observable.concat") {
	    // 1
	    let first = Observable.of(1, 2, 3)
	    let second = Observable.of(4, 5, 6)

	    // 2
	    let observable = Observable.concat([first, second])

	    observable.subscribe(onNext: {
	        print($0)
	    })

	    /* Prints:
	     1
	     2
	     3
	     4
	     5
	     6
	    */
	}
	```

	* 코드를 보면 `startWith(_:)` 보다는 훨씬 읽기 편하다. (번역대로 first와 second를 연결한다는 의미이므로)
	* 출력하면 생각했던대로 나온다. `1 2 3 4 5 6`
* `Observable.concat(_:)` 정적 함수는 순서가 지정된 observable 컬렉션 (array 같은)을 취한다.
* 첫 번째 콜렉션의 sequence의 각 요소들이 완료될 떄까지 구독하고, 이어서 다음 sequence를 같은 방법으로 구독한다. 이러한 과정은 콜렉션의 모든 observable 항목이 사용될 때까지 반복된다.
* 만약에 내부의 observable의 어떤 부분에서 에러가 방출되면, `concat`된 observable도 에러를 방출하며 완전 종료된다.

### 3. concat(_:)

* 다음과 같은 코드를 확인해보자

	```swift
	example(of: "concat") {
	    let germanCities = Observable.of("Berlin", "Münich", "Frankfurt")
	    let spanishCities = Observable.of("Madrid", "Barcelona", "Valencia")

	    let observable = germanCities.concat(spanishCities)
	    observable.subscribe(onNext: { print($0) })
	}
	```

	* 이 변형은 기존의 observable에 적용된다. 기존 observable이 완료될 때까지 기다린 다음, `observable`에 등록된다.
	* 인스턴스 생성과는 별도로, 상기 코드는 `Observable.concat`과 똑같이 작동한다.
* 이런 observable의 결합은, 반드시 두 observable의 요소들이 같은 타입일 때 가능하다. 만약에 다른 타입의 observable을 합치려고 하면 컴파일러 에러가 발생할 것이다.


### 4. concatMap(_:)

* ~이름에서 유추할 수 있듯이~  Ch.7에서 배운 `flatMap`과 밀접한 관련이 있다. (`flatMap` [다시보기](https://github.com/fimuxd/RxSwift/blob/master/Lectures/07_Transforming%20Operators/CH7_TransformingOperators.md#1-flatmap))
* `flatMap`을 통과하면 `Observable` sequence가 구독을 위해 리턴되고, 방출된 observable들은 합쳐지게 된다.
* `concatMap`은 각각의 sequence가 다음 sequence가 구독되기 전에 합쳐진다는 것을 보증한다.
* 다음의 코드를 확인해보자.

	```swift
	example(of: "concatMap") {
	    // 1
	    let sequences = ["Germany": Observable.of("Berlin", "Münich", "Frankfurt"),
	                     "Spain": Observable.of("Madrid", "Barcelona", "Valencia")]

	    // 2
	    let observable = Observable.of("Germany", "Spain")
	        .concatMap({ country in
	            sequences[country] ?? .empty() })

	    // 3
	    _ = observable.subscribe(onNext: {
	        print($0)
	    })
	}
	```

	* 주석을 따라 하나씩 확인해보면,
		* 1) 독일과 스페인 도시명을 나타낼 두개의 sequence를 준비한다.
		* 2) sequence는 해당 국가의 도시명을 내보내는 sequence에 매핑되는 국가명을 내보낸다.
		* 3) 특정 국가의 전체 sequence를 출력한 후 다음 국가를 확인한다.
* 이로써 두개의 sequence들을 어떻게 *append* 하는지 배웠다. 이제 여러개의 sequence의 요소들을 어떻게 *combining* 하는지 배울 것이다.

## C. 합치기

### 1. merge()

* RxSwift에는 sequence들을 합치는 다양한 방법들이 있다. 시작하기에 가장 쉬운 방법은 `merge`다.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/3.merging.png?raw=true" height = 250>

* 하기의 코드를 살펴보자

	```swift
	example(of: "merge") {
	    // 1
	    let left = PublishSubject<String>()
	    let right = PublishSubject<String>()

	    // 2
	    let source = Observable.of(left.asObservable(), right.asObservable())

	    // 3
	    let observable = source.merge()
	    let disposable = observable.subscribe(onNext: {
	        print($0)
	    })

	    // 4
	    var leftValues = ["Berlin", "Münich", "Frankfurt"]
	    var rightValues = ["Madrid", "Barcelona", "Valencia"]

	    repeat {
	        if arc4random_uniform(2) == 0 {
	            if !leftValues.isEmpty {
	                left.onNext("Left: " + leftValues.removeFirst())
	            }
	        } else if !rightValues.isEmpty {
	            right.onNext("Right :" + rightValues.removeFirst())
	        }
	    } while !leftValues.isEmpty || !rightValues.isEmpty

	    // 5
	    disposable.dispose()
	}
	```

	* 주석을 따라 하나씩 확인해보자.
		* 1) 두 개의 PublishSubject 인스턴스를 준비한다.
		* 2) 각각의 PublishSubject를 `asObservable()`을 이용해서 Observable로 만들고, 이 observable들 타입으로 갖는 `source`라는 이름의 observable을 만든다.
		* 3) 두 개의 observable을 합쳐서 구독하도록 한다.
		* 4) 각각의 observable에서 랜덤으로 값을 뽑는 로직을 작성한다. `leftValue`와 `rightValue`에서 모든 값을 출력한 후 종료될 것이다.
		* 5) 아직 `Subject`는 완료되지 않았기 때문에, `dispose()`를 호출하여 메모리 누수가 일어나지 않도록 한다.
		* 출력값은 랜덤이므로 구동할 때마다 다르게 나타날 것이다.
* `merge()` observabled은 각각의 요소들이 도착하는대로 받아서 방출한다. 사전에 정의된 규칙같은 것은 없다.
* 아마 어떻게, 그리고 언제 `merge()`가 완료되는지 궁금할 것이다.
	* `merge()`는 source sequence**와** 모든 내부 sequence들이 완료되었을 때 끝난다.
	* 내부 sequence 들은 서로 아무런 관계가 없다.
	* 만약 어떤 sequence라도 에러를 방출하면 `merge()`는 즉시 에러를 방출하고 종료된다.
* 상기 코드를 다시 확인해보면, `merge()`는 observable들 요소로 가지고 방출하는 *source* observable을 취하는 것을 알 수 있다. 즉, `merge()`에 많은 양의 sequence들을 보낼 수 있다는 뜻이다.

### 2. merge(maxConcurrent:)

* 합칠 수 있는 sequence의 수를 제한하기 위해서 `merge(maxConcurrent:)`를 사용할 수 있다.
* maxConcurrent 수에 도달할 때까지, 변동은 계속해서 일어난다.
* limit에 도달한 이후에 들어오는 observable을 대기열에 넣는다. 그리고 현재 sequence 중 하나가 완료되자마자 구독을 시작한다.
* 이러한 제한 메소드를 `merge()`보다 덜 사용하게 될 가능성이 크다. 하지만 적절한 용도가 있다는 것을 항상 기억해두자. 네트워크 요청이 많아질 때 리소스를 제한하거나 연결 수를 제한하기 위해 `merge(maxConcurrent:)` 메소드를 쓸 수 있다.

## D. 요소 결합하기

* RxSwift의 주요한 연산자 계열은 **`combineLatest`** 이다.

### 1. combineLatest(_:_:resultSelector:)

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/4.%20combiningElements.png?raw=true" height = 200>

* 내부(결합된) sequence들은 값을 방출할 때마다, 제공한 클로저를 호출하며 우리는 각각의 내부 sequence들의 최종값을 받는다.
* 여러 TextField를 한번에 관찰하고 값을 결합하거나 여러 소스들의 상태들을 보는 것과 같은 app이 있다.
* 이런 기능들은 복잡해 보이지만 상당히 간단하다. 아래 코드를 통해 살펴보자.

	```swift
	example(of: "combineLast") {
	    let left = PublishSubject<String>()
	    let right = PublishSubject<String>()

	    // 1
	    let observable = Observable.combineLatest(left, right, resultSelector: { lastLeft, lastRight in
	        "\(lastLeft) \(lastRight)"
	    })

	    let disposable = observable.subscribe(onNext: {
	        print($0)
	    })

	    // 2
	    print("> Sending a value to Left")
	    left.onNext("Hello,")
	    print("> Sending a value to Right")
	    right.onNext("world")
	    print("> Sending another value to Right")
	    right.onNext("RxSwift")
	    print("> Sending another value to Left")
	    left.onNext("Have a good day,")

	    // 3
	    disposable.dispose()

	    /* Prints:
	     > Sending a value to Left
	     > Sending a value to Right
	     Hello, world
	     > Sending another value to Right
	     Hello, RxSwift
	     > Sending another value to Left
	     Have a good day, RxSwift
	    */
	}
	```

	* 주석을 따라 확인해보자
		* 1) 앞서 만든 두개의 PublishSubject들을 각 Subject의 최종값으로 묶는 observable을 만들자.
		* 2) 만든 observable에 값들을 넣어보자.
		* 3) observable을 dispose 하는 것을 잊지 말자.
	* 이 예제를 통해서 다음과 같은 사실을 확인할 수 있다.
		* 각 sequence의 최신값을 인수로 받는 클로저를 사용하여 observable의 항목들을 결합한다. 이 예제에서의 조합은 `left`및 `right` 값을 연결한 `String` 값이다. 결합된 observable에 의해 방출되는 요소의 타입이 곧 클로저의 리턴 타입인 것처럼 이러한 방출 타입은 뭐든지 될 수 있다.
		* 결합된 observable이 하나의 값을 방출하기 전까지는 아무일도 일어나지 않는다. 한번 값을 방출한 이후에는 클로저가 각각의 observable이 생성하는 최종의 값을 받게 된다.
		* `combineLatest(_:_:resultSelector:)`는 클로저 호출을 시작하기 전에, 모든 observable이 하나의 값을 방출하는 순간을 기다린다. 이는 곧 `startWith(_:)` 연산자를 통해 초기값을 주는 것이 업데이트 시간을 부여하는 것으로 사용될 수 있는 기회가 된다는 것을 의미한다.
* Ch.7의 `map(_:)`처럼, `combineLatest(_:_:resultSelector:)`도 클로저의 리턴타입으로 observable을 생성한다. 이 것은 연산자를 이용해 새로운 유형으로 전환할 수 있는 좋은 기회다.
* 일반적인 패턴은 값을 튜플에 결합한 다음 체인 아래로 전달하는 것이다. 예를 들어 값을 결합한 다음 필터를 호출하는 등의 작업을 할 수 있다.

### 2. combineLatest(_,_,resultSelector:)

* `combineLatest` 계열에는 다양한 연산자들이 있다. 이들은 2개부터 8개까지의 observable sequence를 파라미터로 가진다. 앞서 언급한대로, sequence 요소의 타입이 같을 필요는 없다.
* 하기 코드를 확인해보자

	```swift
	example(of: "combine user choice and value") {
	    let choice:Observable<DateFormatter.Style> = Observable.of(.short, .long)
	    let dates = Observable.of(Date())

	    let observable = Observable.combineLatest(choice, dates, resultSelector: { (format, when) -> String in
	        let formatter = DateFormatter()
	        formatter.dateStyle = format
	        return formatter.string(from: when)
	    })

	    observable.subscribe(onNext: { print($0) })
	}
	```

	* 이 예제는 유저가 셋팅을 바꿀 때마다 자동적으로 화면에 업데이트를 띄워준다.

### 3. combineLatest([],resultSelector:)

* array내의 최종 값들을 결합하는 형태도 있다.
* 상기 예제에서 `combineLatest(_:_:resultSelector:)`를 통해 작성한 코드를 하기와 같이 변형할 수 있다.

	```swift
	    let observable = Observable.combineLatest([left, right]) { strings in
	        strings.joined(separator: " ")
	    }
	```

### 4. zip

* 또 다른 결합 연산자로는 `zip`이 있다.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/5.%20zip.png?raw=true" height = 200>

* 다음과 같은 코드를 작성해보자.

	```swift
	example(of: "zip") {

	    // 1
	    enum Weatehr {
	        case cloudy
	        case sunny
	    }

	    let left:Observable<Weatehr> = Observable.of(.sunny, .cloudy, .cloudy, .sunny)
	    let right = Observable.of("Lisbon", "Copenhagen", "London", "Madrid", "Vienna")

	    // 2
	    let observable = Observable.zip(left, right, resultSelector: { (weather, city) in
	        return "It's \(weather) in \(city)"
	    })

	    observable.subscribe(onNext: {
	        print($0)
	    })

	    /* Prints:
	     It's sunny in Lisbon
	     It's cloudy in Copenhagen
	     It's cloudy in London
	     It's sunny in Madrid
	     */
	}
	```

	* 주석을 따라 확인해보자
		* 1) `Weather` enum을 작성하고, 두개의 Observable을 만든다.
		* 2) `zip(_:_:resultSelector:)`를 이용하여 두개의 Observable을 병합한다.
	* `zip(_:_:resultSelector:)`은 다음과 같이 동작한다.
		* 1) 제공한 observable을 구독한다.
		* 2) 각각의 observable이 새 값을 방출하길 기다린다.
		* 3) 각각의 새 값으로 클로저를 호출한다.
	*  상기 코드에서 `Vienna`가 출력되지 않은 것을 알 수 있다. 왜일까?
		* 이 것은 `zip`계열 연산자의 특징이다.
		* 이들은 일련의 observable이 새 값을 각자 방출할 때까지 기다리다가, 둘 중 하나의 observable이라도 완료되면, `zip` 역시 완료된다.
		* 더 긴 observable이 남아있어도 기다리지 않는 것이다. 이렇게 sequence에 따라 단계별로 작동하는 방법을 가르켜 **indexed sequencing** 이라고 한다. 	  
* Swift에도 `zip(:_:_)` 연산자가 있다. 새로운 튜플조합을 두 조합으로부터 만드는 작업을 한다. 하지만 이건 구현에 불과하다. RxSwift는 `combineLatest`처럼 2 ~ 8개의 observable에 대한 변형과 조합을 제공한다.

## E. Triggers

* 여러개의 observable을 한번에 받는 경우가 있을 것이다. 이럴 때 다른 observable들로부터 데이터를 받는 동안 어떤 observable은 단순히 방아쇠 역할을 할 수 있다.

### 1. withLatestFrom(_:)

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/6.%20trigger.png?raw=true" height = 200>

* 다음과 같은 코드를 작성해보자.

	```swift
	example(of: "withLatestFrom") {
	    // 1
	    let button = PublishSubject<Void>()
	    let textField = PublishSubject<String>()

	    // 2
	    let observable = button.withLatestFrom(textField)
	    _ = observable.subscribe(onNext: { print($0) })

	    // 3
	    textField.onNext("Par")
	    textField.onNext("Pari")
	    textField.onNext("Paris")
	    button.onNext(())
	    button.onNext(())
	}
	```  

	* 주석을 따라 확인해보자
		* 1) `button`과 `textField`라는 두개의 PublishSubject를 만든다.
		* 2) `botton`에 대해 `withLatestFrom(textField)`를 호출한 뒤, 구독을 시작한다.
		* 3) `button`에 새 이벤트가 추가되기 직전에 `textField`가 추가된 최신 값인 `Paris`가 출력된다. 그 전의 값들은 무시된다.

### 2. sample(_:)

* `withLatestFrom(_:)`과 거의 똑같이 작동하지만, 한 번만 방출한다. 즉 여러번 새로운 이벤트를 통해 방아쇠 당기기를 해도 한번만 출력되는 것.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/7.%20withLatestFrom.png?raw=true" height = 200>

* 상기 코드에서 주석 2 부분을 아래와 같이 변경해보자.

	```swift
	let observable = textField.sample(button)
	```

	* 이렇게 하면 `Paris`가 한번만 출력되는 것을 알 수 있다.
* `withLatestFrom(_:)`을 가지고 `sample(_:)`처럼 작동하게 하려면 `distinctUntilChanged()`와 함께 사용하면 된다. 아래의 코드처럼 작성하면 `Paris`가 한번 출력된다.

	```swift
	    let observable = button.withLatestFrom(textField)
	    _ = observable
	        .distinctUntilChanged()
	        .subscribe(onNext: { print($0) })
	```

* `withLatestFrom(_:)`은 데이터 observable을 파라미터로 받고, `sample(_:)`은 trigger observable을 파라미터로 받는다. 실수하기 쉬운 부분이니 주의할 것

## F. Switches

### 1. amb(_:)

* `amb(_:)`에서 amb는 *ambiguous모호한* 이라 생각하면 된다.
* 두가지 sequence의 이벤트 중 어떤 것을 구독할지 선택할 수 있게 한다.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/8.switches.png?raw=true" height = 200>

* 아래의 코드를 확인해보자.

	```swift
	example(of: "amb") {
		let left = PublishSubject<String>()
		let right = PublishSubject<String>()

		// 1
		let observable = left.amb(right)
		let disposable = observable.subscribe(onNext: { value in
			print(value)
		})

		// 2
		left.onNext("Lisbon")
		right.onNext("Copenhagen")
		left.onNext("London")
		left.onNext("Madrid")
		right.onNext("Vienna")

		disposable.dispose()
	}
	```

	* 주석을 따라 하나씩 살펴보면
		* 1) `left`와 `right`를 사이에서 모호하게 작동할 observable을 만든다.
		* 2) 두 개의 observable에 모두 데이터를 보낸다.
* `amb(_:)` 연산자는 `left`, `right` 두 개 모두의 observable을 구독한다. 그리고 두 개중 어떤 것이든 요소를 모두 방출하는 것을 기다리다가 하나가 방출을 시작하면 나머지에 대해서는 구독을 중단한다. 그리고 처음 작동한 observable에 대해서만 요소들을 늘어놓는다.
* 처음에는 어떤 sequence에 관심이 있는지 알 수 없기 때문에, 일단 시작하는 것을 보고 결정하는 것이다.

### 2. switchLatest()

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/9.switchlatest.png?raw=true" height = 250>

* 다음과 같은 코드를 작성해보자.

	```swift
	example(of: "switchLatest") {
	    // 1
	    let one = PublishSubject<String>()
	    let two = PublishSubject<String>()
	    let three = PublishSubject<String>()

	    let source = PublishSubject<Observable<String>>()

	    // 2
	    let observable = source.switchLatest()
	    let disposable = observable.subscribe(onNext: { print($0) })

	    // 3
	    source.onNext(one)
	    one.onNext("Some text from sequence one")
	    two.onNext("Some text from sequence two")

	    source.onNext(two)
	    two.onNext("More text from sequence two")
	    one.onNext("and also from sequence one")

	    source.onNext(three)
	    two.onNext("Why don't you see me?")
	    one.onNext("I'm alone, help me")
	    three.onNext("Hey it's three. I win")

	    source.onNext(one)
	    one.onNext("Nope. It's me, one!")

	    disposable.dispose()

	    /* Prints:
	     Some text from sequence one
	     More text from sequence two
	     Hey it's three. I win
	     Nope. It's me, one!
	     */
	}
	```

	* 주석을 따라가며 확인해보자.
		* 1) 3개의 `String` PublicSubject를 만들고, `Observable<String>`의 PublishSubject를 만든다.
		* 2) `source`에 `switchLatest()`를 적용시키고 구독한다.
		* 3) 코드를 입력하고 출력되는 결과를 확인한다.
	* `source` observable로 들어온 마지막 sequence의 아이템만 구독하는 것을 볼 수 있다. 이 것이 `switchLatest`의 목적이다.
* `switchLatest()`는 Ch.7의 `flatMapLatest(_:)`와 유사하다. `flatMapLatest(_:)`는 observable의 마지막 값들을 매핑하여 구독한다. (`flatMapLatest` [다시보기](https://github.com/fimuxd/RxSwift/blob/master/Lectures/07_Transforming%20Operators/CH7_TransformingOperators.md#2-flatmaplatest))  

## G. sequence내의 요소들간 결합

### 1. reduece(_:_:)

* Swift 표준 라이브러리의 `reduce(:_:_)`를 이미 알고 있을 것이다.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/10.reduce.png?raw=true" height = 150>

* 다음 코드를 살펴보자.

	```swift
	example(of: "reduce") {
	    let source = Observable.of(1, 3, 5, 7, 9)

	    // 1
	    let observable = source.reduce(0, accumulator: +)
	    observable.subscribe(onNext: { print($0) } )

	    // 주석 1은 다음과 같은 의미다.
	    // 2
	    let observable2 = source.reduce(0, accumulator: { summary, newValue in
	        return summary + newValue
	    })
	    observable2.subscribe(onNext: { print($0) })
	}
	```

	* `reduce(:_:_)`는 제공된 초기값(예제에서는 `0`)부터 시작해서 source observable이 값을 방출할 때마다 그 값을 가공한다.
	* observable이 완료되었을 때, `reduce(:_:_)`는 결과값`25`을 방출하고 완료된다.

### 2. scan(_:accumulator:)

* 다음 그림에서 `sequence`와 `scan(_:accumulator)` 이 후의 값이 어떻게 다른지 확인해보자.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/11.%20scan.png?raw=true" height = 150 >

* 다음 코드를 살펴보자.

	```swift

	example(of: "scan") {
	    let source = Observable.of(1, 3, 5, 7, 9)

	    let observable = source.scan(0, accumulator: +)
	    observable.subscribe(onNext: { print($0) })

	    /* Prints:
	     1
	     4
	     9
	     16
	     25
	    */
	}
	```

	* `reduce(:_:_)` 처럼 작동하지만, 리턴값이 Observable이다.
* `scan(_:accumulator:)`의 쓰임은 광범위 하다. 총합, 통계, 상태를 계산할 때 등 다양하게 쓸 수 있다.
* 자세한 예제는 **Ch.20 RxGesture**에서 배울 수 있다.

## H. Challenges

### The zip case

* `zip` 연산자를 사용해서 상기의 `scan(_:accumulator:)` 예제에서 현재값과 현재 총합을 동시에 나타내도록 해보자.
* 혹시 다른 연산자를 써서 같은 결과를 나타낼 수 있는지도 확인해보자.

> A.
>
> ```swift
> example(of: "Challenge 1") {
>     let source = Observable.of(1, 3, 5, 7, 9)
>     let observable = source.scan(0, accumulator: +)
>
>     let _ = Observable.zip(source, observable, resultSelector: { (current, total) in
>         return "\(current) \(total)"
>     })
>         .subscribe(onNext: { print($0) })
> }
> ```
>
> 또는
>
> ```swift
> example(of: "Challenge 2") {
>     let source = Observable.of(1, 3, 5, 7, 9)
>     let observable = source.scan((0,0), accumulator: { (current, total) in
>         return (total, current.1 + total)
>     })
>         .subscribe(onNext: { tuple in
>             print("\(tuple.0) \(tuple.1)")
>         })
> }
> ```

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
