##### 가람님 과제

# `PublishRelay`, `BehaviorRelay`, `Variable`
> 각각의 공통점과 차이점 특징, 어떤 기능에 쓰이면 좋을지 생각해봅시다.

## 답변

두개를 비교해보니까,<p>
`PublishRelay`는 `PublishSubject`를 래핑해서 가지고 있고, <p>
`BehaviorRelay`는 `BehaviorSubject`를 같은 방식으로 가지고 있네요.  

### 둘과 variable의 공통점

- `ObservableType`을 상속함 
- _error_ 나 _complete_ 를 통해서 완전종료될 수 없다는 점
- 새로운 element를 갖기 위해서 observable이나 subject에서 사용했던 `onNext(_: )` 키워드는 쓸 수 없네요. 대신 같은 작용?을 하는 `accept` 메소드가 있습니다. 
- relay 를 observable이나 subject 처럼 구독하고 싶을 때 사용할 수 있는 `asObservable` 메소드가 있습니다. 

### 두 relay간 차이점

- 정의상 단 하나의 차이점이 있습니다. `BehaviorRelay`는 variable 처럼 `BehaviorSubject`의 현재값을 알 수 있는 `value` 라는 프로퍼티를 가집니다. `PublishRelay`에는 이 프로퍼티가 없네요. 

### 각각을 어느용도에서 사용할 수 있을까

- `PublishRelay`: `PublishSubject`의 특성상, 구독한 subject에서 구독 이전에 발생한 이벤트들에 대해서는 알 수 없고, 구독 이후에 발생하는 이벤트들만 알 수 있으니까.. 그런 기능에 적합하지 않을까요? 어떤 캘린더 기능을 기존에 쓰던 구글캘린더와 동기화 시킬 때, 동기화 이전에 기록해두었던 지난 일정들은 불러오지 않기.. 같은 기능 

- `BehaviorRelay`: 역시 래핑당하는 `BehaviorSubject`의 특성을 생각해보면, 구독한 subject 이전에 발생한 이벤트라도, subject를 선언할 때 설정해두었던 버퍼사이즈만큼의 이벤트는 불러옵니다. 그러니까.. 검색기능에 보면 최근 검색어 뜨는 것 있잖아요. 검색창을 탭 했을 때 탭하기 이전에 검색한 기록 n 개를 최근검색어 label 하단에 보여주게 하는 기능에 적용할 수 있을 것 같습니다.

#### 역질문1: Subject 자체로써 쓰지 않고, 한번더 래핑하여 Relay의 형태로 사용하는 이유가 뭐죠?

Subject의 경우 complete나 error를 맞이할 수 있습니다. 하지만 ~Relay의 경우 complete나 error를 받지 않으므로 생기는 이점이 있을 것 같아요. 예를들어 View-> ViewModel로 가는 스트림의 경우 dispose되기 전까지 계속 작동해야 하는데, 컴플리트나 에러가 안된다는 점에서 더 적절한 사용 용도겠지요!

#### 역질문2: 그럼 `BehaviorRelay`와 `Variable`의 차이는 뭔지.

BehaviorRelay는 accept(E) 가 생기고, value가 get-only property가 되었다는 점에서 Variable과 차이가 있습니다. value를 통해 get, set을 하기에 너무 variable이 남용되어서 그렇지 않나 하는 생각이 있는데, 왜그럴지는 한번 더 연구해봅시다..!




