# Ch.7 Transforming Operators

## A. 시작하기

* RxSwift를 배우기 이전에는 아마 iOS나 Swift를 처음 배울 때 느꼈던 것처럼 아주 난해하고 이해하기 어려운 라이브러리라고 느껴졌을 것이다.
* 이 장에서는 RxSwift의 연산자 카테고리에서 제일 중요한 연산자라 할 수 있는 *변환연산자transforming Operators*에 대해서 배울 것이다.
* 아마 변환연산자는 subscriber를 통해 observable에서 데이터를 준비하는 것 같은 모든 상황에서 쓰일 수 있다.
* 앞서 본 `filter`처럼 여기서도 `map(_:)`이나 `flatMap(_:)`같이 Swift 표준 라이브러리와 RxSwift 간에 유사점이 있는 연산자들을 확인할 수 있다.

## B. 변환연산자의 요소들

* Observable은 독립적으로 요소들을 방출하지만, observable을 table 또는 collection view와 바인딩 하는 것처럼 어쩔 때는 이 것을 조합하고 싶을 수 있다.

### 1. toArray

* Observable의 독립적 요소들을 array로 넣는 가장 편리한 방법은 `toArray`를 사용하는 것이다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/07_Transforming%20Operators/1.%20toArray.png?raw=true" height = 200>
	
	* 상기의 marble diagram을 보면 `toArray`는 observable sequence의 요소들은 array의 요소들로 넣는다. 그리고 이렇게 구성된 array를 `.next` 이벤트를 통해 subscriber에게 방출한다.

* 하기의 코드를 살펴보자.

	```swift
	example(of: "toArray") {
		let disposeBag = DisposeBag()
		
		// 1
		Observable.of("A", "B", "C")
			// 2
			.toArray()
			.subscribe(onNext: {
				print($0)
			})
			.disposed(by: disposeBag)
			
		/* Prints:
			["A", "B", "C"]
		*/
	}
	``` 
	
	* 주석을 따라 하나씩 살펴보자,
		* 1) `String`의 Observable을 만든다.
		* 2) `toArray`를 이용하여 Observable의 요소들을 array에 넣는다.

### 2. map

* RxSwift의 `map` 연산자는 Observable 에서 동작한다는 점만 제외하면 Swift 표준 라이브러리의 `map`과 같다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/07_Transforming%20Operators/2.%20map.png?raw=true" height = 200>

	* `map`은 각각의 요소에서 2를 곱하는 클로저를 갖는다.

* 하기의 코드를 살펴보자.

	```swift
	example(of: "map") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    let formatter = NumberFormatter()
	    formatter.numberStyle = .spellOut
	    
	    // 2
	    Observable<NSNumber>.of(123, 4, 56)
	        // 3
	        .map {
	            formatter.string(from: $0) ?? ""
	        }
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	}
	```
	
	* 주석을 따라 확인해보자.
		* 1) 각 숫자의 음절을 출력하는 number formatter를 만든다.
		* 2) `NSNumbers`의 Observable을 만든다. 이렇게 하면 다음 과정에서 formatter를 쓸 때 `Int`를 전환할 필요가 없다.
		* 3) `map`을 사용하여, 각 숫자의 음절이 나오도록 한다. 만약 `nil`값이 나오면 빈 `Strring`을 출력하도록 한다. 
		* 프린트된 값은 `one hundred twenty-three, four, fifty-six`

### 3. enumerated

* Ch.5에서 `enumerated`와 `map`을 `filter`와 사용해본 적이 있다. ([다시보기](https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/Ch5.%20FilteringOperators.md#3-enumerated))
* 여기서 다시한번 살펴보자. 아래의 코드를 작성한다.

	```swift
	example(of: "enumerated and map") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    Observable.of(1, 2, 3, 4, 5, 6)
	        // 2
	        .enumerated()
	        // 3
	        .map { index, interger in
	            index > 2 ? interger * 2 : interger
	        }
	        // 4
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	        
	        /* Prints:
	        1 2 3 8 10 12
	        */
	}
	```
	
	* 주석을 따라 하나씩 살펴보면,
		* 1) 정수들의 Observable을 만든다.
		* 2) `enumerated`를 사용해서 요소들의 값과 index를 갖는 tuple을 만든다.
		* 3) `map`을 사용해서 tuple의 값을 살펴본다. 만약 요소들의 `index`가 2보다 크면, 값에 2를 곱한 것을 리턴한다. 그렇지 않으면, 해당 값을 그대로 리턴한다. 
		* 4) 해당 Observable을 구독하고 값을 방출한다. 

## C. 내부의 Observable 변환하기

* 아마 상기 케이스를 통해 한가지 의문이 생겼을 것이다. '만약 Observable' 속성을 갖는 Observable은 어떻게 사용할 수 있을까?
* 하기 코드를 작성해보자.

	```swift
	struct Student {
	    var score: BehaviorSubject<Int>
	}
	```
	
	* `Student`는 `BehaviorSubject<Int>` 속성의 `score`라는 속성을 갖는 struct다. 
	* RxSwift는 `flatMap` 연산자 내에 몇 가지 연산자를 가지고 있다. 이들은 observable 내부로 들어가서 observable 속성들과 작업한다. 
* 여기서 배울 개념은 RxSwift를 배우는 누구에게든 어려운 개념이다. 처음에는 복잡해보이겠지만, 하나씩 차근차근히 들여다본 후에는 자신있게 사용할 수 있을 것이다.

### 1. flatMap

* 먼저 문서에서의 `flatmap`에 대한 정의를 확인해보자. '`Observable sequence`의 각 요소를 `Observable sequence`에 투영하고 `Observable sequence`를 `Observable sequence`로 병합한다.' ~뭔솔?~
* 아래의 marble diagram을 살펴보자

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/07_Transforming%20Operators/3.%20flatmap.png?raw=true" height = 250>

	* 첫 째줄의 Observable이 마지막 줄의 구독자에 가기까지의 과정을 보여주고 있다.
	* 첫 Observable은 `Int`타입의 `value` 값을 가지고 있다. 각각의 고유한 값은 `01` = `1`, `02` = `2`, `03` = `3`을 의미한다.
	* `01`부터 시작하여 `flatMap`은 객체를 수신하고 value 속성에 접근하여 10을 곱한다. 그리고 `01`로 부터 변환된 새 값을 새 `Observable` (01의 경우 flatMap 아래 첫 번째 줄)에 투영한다. 이렇게 subscriber(마지막줄)에게 줄 observable까지 내려간다.
	* 이 후 `01`의 값 속성이 4로 변경된다. 이 부분은 그림에서 표현하지 않았다. 너무 복잡해지므로. 다만, `01`의 값이 바뀌었다는 증거는 해당 Observable에서 값이 40으로 변형된 것을 보고 확인할 수 있다.
	* 첫 째줄의 Observable에서 방출하는 다음 값은 `02`다. 역시 `flatMap`이 받는다. 이 값은 `20`으로 전환되고 역시 새 Observable에 투영된다. 이 후 `02`의 값은 `5`로 바뀔 것이고, 이 값 역시 `50`으로 전환된다.
	* 최종적으로 `03`을 `flatMap`이 받아 변환시킨다.

* `flatMap`은 observable의 observable 값을 투영하고 변환한 다음, target observable로 만든다. 아래의 코드를 통해 직접 사용해보자.

	```swift
	example(of: "flatMap") {
	    let disposeBag = DisposeBag()
	    
	    // 1
	    let ryan = Student(score: BehaviorSubject(value: 80))
	    let charlotte = Student(score: BehaviorSubject(value: 90))
	    
	    // 2
	    let student = PublishSubject<Student>()
	    
	    // 3
	    student
	        .flatMap{
	            $0.score
	        }
	        // 4
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	    
	    // 5
	    student.onNext(ryan)    // Printed: 80
	    
	    // 6
	    ryan.score.onNext(85)   // Printed: 80 85
	    
	    // 7
	    student.onNext(charlotte)   // Printed: 80 85 90
	    
	    // 8
	    ryan.score.onNext(95)   // Printed: 80 85 90 95
	    
	    // 9
	    charlotte.score.onNext(100) // Printed: 80 85 90 95 100
	}
	```
	
	* 주석을 따라 하나씩 살펴보자.
		* 1) `ryan`과 `charlotte`라는 두 개의 `Student` 인스턴스를 만들자
		* 2) `Student` 타입의 source subject를 만든다.
		* 3) `flatMap`을 사용해서 `student` subject와 subject가 갖는 `score`값에 접근한다. `score`를 수정하지 말고 일단 통과하게 하자.
		* 4) `.next` 이벤트의 요소를 구독하여 프린트되게 한다. 하지만 이 때까지는 아무 것도 출력되지 않는다.
		* 5) `ryan`이라는 `Student` 인스턴스를 `.onNext` 이벤트를 통해 추가한다. 이렇게 하면 `ryan`의 `score`값이 출력된다.
		* 6) `ryan`의 `score`값을 변경해보자. 이렇게 하면 `ryan`의 새 점수가 출력된다.
		* 7) 또 다른 `Student` 인스턴스인 `chalotte`를 추가하자. 이렇게 하면 `chalotte`의 점수가 출력된다.
		* 8) `ryan`의 점수를 다시 바꿔보자. 역시 변경된 값이 출력된다.
			* 왜냐하면 `flatMap`은 source가 되는 observable에 추가된 각 요소에 대해 생성한 모든 observable 정보를 가지고 있기 때문이다.
		* 9) 이제 `charlotte`의 값도 바꿔보자. 당연히 새로 입력한 값이 프린트 될 것이다.
* 요약하자면, `flatMap`은 각 Observable의 변화를 계속 지켜본다. 

### 2. flatMapLatest

* 아마 상기의 `flatMap`에서 가장 최신의 값만을 확인하고 싶을 때도 있을 것이다. 이럴 때 `flatMapLatest`를 사용할 수 있다.
* `flatMapLatest` = `map` + `switchLatest`
	* `map`과 `switchLatest` 연산자를 합친 것이 `flatMapLatest`라고 할 수 있다. 
	* `switchLatest`는 가장 최근의 observable 에서 값을 생성하고 이전 observable을 구독 해제한다.
	* `switchLatest`에 대해서는 **Ch.9 Combining Operators** 에서 자세히 배울 것이다.  
* 문서상 `flatMapLatest` 정의를 살펴보자. 'observable sequence의 각 요소들을 observable sequence들의 새로운 순서로 투영한 다음, observable sequence들의 observable sequence 중 가장 최근의 observable sequence 에서만 값을 생성한다.' ~네???~

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/07_Transforming%20Operators/4.%20flatMapLatest.png?raw=true" height = 250>

	* 그림을 살펴보자. `flatMapLatest`는 `flatMap`과 같이, observable 속성 내의 observable 요소까지 접근한다. 
	* 각각의 변환된 요소들은 구독자에게 제공될 새로운 observable로 flatten 된다. `flatMapLatest`가 `flatMap`과 다른 점은, 자동적으로 이전 observable을 구독해지한다는 것이다. 
	* `01`은 `flatMapLatest`에 의해 수신되고, 그 값을 10으로 변환한 뒤, `01`에 대한 새로운 observable에 값으로 투영된다. 여기까진 `flatMap`과 동일하다. 하지만 `flatMapLatest`는 이후 `02`를 받고 이 것을 `02`에 대한 observable로 전환한다. 왜냐하면 여기까진 이게 최신의 값이기 때문에.
	* `01`의 값이 변경되었을 때, `flatMapLatest`는 변경된 값을 무시한다. 
	* 이 과정은 `flatMapLatest`가 `03`을 받을 때도 반복된 후, 해당 sequence를 스위치 한다. 그리고 이전 것인 `02`를 역시 무시한다. 
	* target observable의 결과값으로는 오직 가장 최근의 observable에서 나온 값만 받게 된다.

* 아래의 코드를 확인해보자

	```swift
	example(of: "flatMapLatest") {
	    let disposeBag = DisposeBag()
	    
	    let ryan = Student(score: BehaviorSubject(value: 80))
	    let charlotte = Student(score: BehaviorSubject(value: 90))
	    
	    let student = PublishSubject<Student>()
	    
	    student
	        .flatMapLatest {
	            $0.score
	    }
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	    
	    student.onNext(ryan)
	    ryan.score.onNext(85)
	    
	    student.onNext(charlotte)
	    
	    // 1
	    ryan.score.onNext(95)
	    charlotte.score.onNext(100)
	    
	    /* Prints:
	    	80 85 90 100
	    */
	}
	```
	
	* `flatMap`에서의 코드와 다른 점은 단 하나, 변경된 `ryan`의 점수인 `85`가 여기서는 반영되지 않는다는 점이다.
	* 왜냐하면, `flatMapLatest`는 이미 `charlotte`의 최근 observable로 전환 했기 때문이다.

### 3. 언제 사용할까?

* `flatMapLatest`는 네트워킹 조작에서 가장 흔하게 쓰일 수 있다.
* 사전으로 단어를 찾는 것을 생각해보자. 사용자가 각 문자 s, w, i, f, t를 입력하면 새 검색을 실행하고, 이전 검색 결과 (s, sw, swi, swif로 검색한 값)는 무시해야할 때 사용할 수 있을 것이다. 

## D. 이벤트 관찰하기

* observable을 observable의 이벤트로 변환해야할 수 있다. 
* 보통 observable 속성을 가진 observable 항목을 제어할 수 없고, 외부적으로 observable이 종료되는 것을 방지하기 위해 error 이벤트를 처리하고 싶을 때 사용할 수 있다. 
* 아래의 코드를 확인해보자.

	```swift
	example(of: "materialize and dematerialize") {
	    
	    // 1
	    enum MyError: Error {
	        case anError
	    }
	    
	    let disposeBag = DisposeBag()
	    
	    // 2
	    let ryan = Student(score: BehaviorSubject(value: 80))
	    let charlotte = Student(score: BehaviorSubject(value: 100))
	    
	    let student = BehaviorSubject(value: ryan)
	    
	    // 3
	    let studentScore = student
	        .flatMapLatest{
	            $0.score
	    }
	    
	    // 4
	    studentScore
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	    
	    // 5
	    ryan.score.onNext(85)
	    ryan.score.onError(MyError.anError)
	    ryan.score.onNext(90)
	    
	    // 6
	    student.onNext(charlotte)
	    
	    /* Prints:
			80 
			85 
			Unhandled error happened: anError
	    */
	}
	```
	
	* 주석을 따라 확인해보자.
		* 1) 에러타입을 하나 생성한다.
		* 2) `ryan`과 `charlotte`라는 두개의 `Student` 인스턴스를 생성하고, `ryan`을 초기값으로 갖는 `student` 라는 BehaviorSubject를 생성한다.
		* 3) `flatMapLatest`를 사용하여 `student`의 `score` 값을 observable로 만든 `studentScore`를 만들어준다. (studentScore는 `Observable<Int>`타입)
		* 4) `studentScore`를 구독한 뒤, 방출하는 `score`값을 프린트한다.
		* 5) `ryan`에 새 점수`85`를 추가하고, 에러를 추가한다. 그리고 다시 새 점수`90`을 추가한다. 
		* 6) `student`에 새 Student 값인 `charlotte`를 추가한다.
	
* 여기서 `materialize` 연산사를 사용하여, 각각의 방출되는 이벤트를 이벤트의 observable로 만들 수 있다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/07_Transforming%20Operators/5.%20materialize.png?raw=true" height = 200>

* 상기의 코드에 `materialize`를 추가해보자. 

	```swift
	 let studentScore = student
	        .flatMapLatest{
	            $0.score.materialize()
	    }
	    
	    ...
	    
	    /* Prints:
	    next(80)
		 next(85)
		 error(anError)
		 next(100)
	    */
	```
	
	* 이제 `studentScore`의 타입은 `Observable<Event<Int>>`인 것을 확인할 수 있다. 그리고 현재 방출하는 이벤트를 구독하게 된다. 
	* 에러는 여전히 `studentScore`의 종료를 발생시키지만, 바깥은 `student` observable은 그대로 살려놓는다. 따라서 새로운 학생인 `charlotte`를 추가하였을 때, 해당 학생의 점수`100`는 성공적으로 출력된다.

* 하지만 이렇게 하면 event는 받을 수 있지만 요소들은 받을 수 없다. 이 문제를 해소하기 위해 `dematerialize`를 사용할 수 있다. 
* `dematerialize`는 기존의 모양으로 되돌려주는 역할을 한다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/07_Transforming%20Operators/6.%20dematerialize.png?raw=true" height = 200>

* 앞서 작성한 코드에서 구독부분을 다음과 같이 바꿔봅시당

	```swift
	    studentScore
	        // 1
	        .filter {
	            guard $0.error == nil else {
	                print($0.error!)
	                return false
	            }
	            
	            return true
	        }
	        // 2
	        .dematerialize()
	        .subscribe(onNext: {
	            print($0)
	        })
	        .disposed(by: disposeBag)
	        
	        ...
	        
	        /* Prints:
	         80
	         85
	         anError
	         100
	        */
	```
	
	* 주석을 따라 확인해보자
		* 1) 에러가 방출되면 필터하고 프린트 할 수 있도록 `guard`문을 작성한다
		* 2) `dematerialize`를 이용하여 `studentScore` observable을 원래의 모양으로 리턴하고, 점수와 정지 이벤트를 방출할 수 있도록 한다. 
		* 결과를 보면, `student` observable은 내부의 `score` observable의 에러를 통해 보호된다.
		* 에러가 프린팅되며, `ryan`의 `studentScore`는 종료된다. 따라서 추가 점수는 출력되지 않는다. 
		* 하지만 `charlotte`를 `student`에 추가했을 때, 해당 학생의 점수는 출력된다.

## E. Challenges

### Ch.5의 Challenge를 수정하여 영숫자 문자 가져오기

* Ch.5 의 도전과제에서, 필터링 연산자를 통해 전화번호를 찾아보는 코드를 작성하였다. 사용자가 입력한 10자리 숫자를 기반으로 연락처를 조회하는데 필요한 코드를 추가했었다. ([다시보기](https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/Ch5.%20FilteringOperators.md#전화번호-만들기))
* 이번 문제의 목표는, 기존의 코드를 수정하여, 문자를 통해 해당 번호로 변환할 수 있도록 하는 것이다. (표준 숫자 키패드가 있다고 가정했을 때, abc는 `2` 패드를 통해, def는 `3` 패드를 통해 입력할 수 있다.) 
* 주어진 starter 파일에는 도우미 closure가 이미 작성되어있다. 이들을 사용해서 규칙에 맞지 않는 입력들을 구독에서 제외할 수 있었다. 그렇다면 남은 것은 무엇일까?
	* 각각의 변환을 수행하기 위해 여러 개의 `map` 연산자를 사용할 것이다.
	* 처음에 `0`을 건너 뛰기 위해 Ch.5에서 `skipWhile`을 사용했던 것처럼, 같은 목적을 위해 여기서도 사용할 것이다.
* `convert`를 통해 출력되는 옵셔널 값을 처리하는 것도 필요하다. 이를 위해 `unwrap`이라는 연산자를 쓸 수 있다. `unwrap`의 쓰임은 다음과 같다.

	```swift
	Observable.of(1, 2, nil, 3)
		.flatMap { $0 == nil ? Observable.empty() : Observable.just($0!) }
		.subscribe(onNext: {
			print($0)
		})
		.disposed(by: disposeBag)
		
	```
	
	* 기존의 RxSwift 라이브러리에서 위와 같이 옵셔널을 처리했다면, `unwrap`을 통해서는 아래와 같이 쓸 수 있다.

	```swift
	Observable.of(1, 2, nil, 3)
		.unwrap()
		.subscribe(onNext: {
			print($0)
		})
		.disposed(by: disposeBag)
	```
	
> A.
>
> ```swift
> input.asObservable()
>         .map(convert)
>         .flatMap {
>             $0 == nil ? Observable.empty() : Observable.just($0!)
>         }	// 이 부분을, RxSwiftExe 라이브러리의 .unwrap()으로 대체할 수 있다. 
>         .skipWhile { $0 == 0 }
>         .take(10)
>         .toArray()
>         .map(format)
>         .map(dial)
>         .subscribe(onNext: {
>             print($0)
>         })
>         .disposed(by: disposeBag)
> ```
> 
> * 프린트 값은 Dialing Florent (603-555-1212)...
> * 하나씩 살펴보면
> 	* map을 통해 convert를 
> 	* flatMap을 통해 옵셔널 핸들링
>  	* skipWhile을 통해 0을 입력할 때는 스킵
> 	* take를 통해 10개의 요소만 받음
> 	* toArray를 통해 observable의 요소들을 array로 변환
> 	* map(format)을 통해 3번과 7번째 인덱스에 "-" 입력
> 	* map(dial)을 통해 해당 전화번호가 연락처에 있는지 확인하고 상황에 따른 출력내용 표시
>
> * 문제에 미리 입력되어 있는 값들은 다음과 같이 읽혀진다 
>
> ```swift
> input.value = ""	// 숫자가 아니므로 무시됨
>     input.value = "0"	// 첫번째가 0이므로 무시됨
>     input.value = "408"	// 하나의 숫자가 아니므로 무시됨
> 
>     input.value = "6"	// 입력됨 (6)
>     input.value = ""	// 숫자가 아니므로 무시됨
>     input.value = "0"	// 입력됨 (6 0)
>     input.value = "3"	// 입력됨 (6 0 3)
> 
>     "JKL1A1B".forEach {
>         input.value = "\($0)"	// "JKL1A1B"를 한 글자씩 입력하는 것인데, JKL1A1B는 표준 숫자 키패드에 의해서 5551212로 변환된다
>     }	// (6 0 3 5 5 5 1 2 1 2)
> 
>     input.value = "9"	// 총 10개의 숫자가 이미 입력되었으므로 무시됨
> ```

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
