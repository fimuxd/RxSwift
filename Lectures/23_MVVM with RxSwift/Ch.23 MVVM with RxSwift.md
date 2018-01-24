# Ch.23 MVVM with RxSwift

## A. MVVM 소개

* MVVM: **M**odel-**V**iew-**V**iew**M**odel; Apple에서 권고하는 MVC(**M**odel-**V**iew-**C**ontroller)와는 구현이 다르다.
* 중요한 것은 MVVM를 오픈 마인드로 접해야 한다는 것. MVVM은 소프트웨어 아키텍처 계의 만병통치약이 아니다. 그저 소프트웨어 패턴으로써, 좋은 앱 아키텍처를 위한 방법 중의 하나 정도로 보는 것이 낫다. 특히 당신이 MVC 마인드 속에 있다면.

### 1. MVC의 배경

* MVC와 MVVM간의 관계의 본질은 무엇일까?
* 이 책을 포함한 대부분의 책들은 MVC 패턴을 통해 샘플 코드를 보여주고 있다. MVC는 대부분의 간단한 앱에서 쓰이는 간단한 패턴으로 다음과 같이 표현할 수 있다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/23_MVVM%20with%20RxSwift/1.MVC.png?raw=true" height = 100>

	* 각각의 클래스들은 카테고리에 등록된다. **controller** 클래스는 가운데에서 model과 view 모두를 업데이트 시킬 수 있다. **view**들은 데이터들을 화면에 보여주는 역할만 하고, 제스처 같은 이벤트들은 controller로 보내진다. **model**은 앱의 상태 지속을 위해 데이터를 읽고 쓴다. 
* MVC는 단순한 구동에서는 아주 좋고 간단한 패턴일 수 있지만, 앱이 커져서 뷰, 모델, 컨트롤러를 모두 포함해 많은 클래스를 가지게 된다면 어떨까? 일단 첫 번째 한계점은 한개의 컨트롤러에 더이상의 코드를 추가할 수 없는 것부터 시작된다. 
* view controller를 통해 iOS앱을 만들기 시작할 때, 모든 것들을 view controller에 때려박는 건 아주 쉽다. 이 때문에 오래전부터 MVC를 두고 "Massive View Controller"라 푸념하는 말들이 나왔다. 왜냐하면 이런 식으로는 controller가 몇백, 몇천 줄의 코드를 안고 있게 되기 때문이다.
* 다만, class를 overloading하는 것이 나쁜 습관인 것이지 이 자체가 MVC 패턴의 단점인 것은 절대 아니다. 이미 Apple의 수많은 개발자들은 MVC 패턴의 팬들이고, 이를 통해 이미 괜찮은 macOS, iOS 소프트웨어를 만들어냈다.
> [Apple의 MVC 문서 읽어보기](https://developer.apple.com/library/content/documentation/General/Conceptual/CocoaEncyclopedia/Model-View-Controller/Model-View-Controller.html)

### 2. MVVM로 탈출하기

* MVVM은 MVC 처럼 보이지만 확실히 더 나은 방법처럼 느껴진다. 대개 MVC를 좋아하는 사람들은 MVVM이 MVC의 수많은 문제들을 쉽게 해결했기 때문에 MVVM 또한 아주 좋아한다. 
* MVVM이 MVC와 차별화되는 출발점은 ViewModel이라는 새로운 카테고리다.

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/23_MVVM%20with%20RxSwift/2.MVVM.png?raw=true" height = 100>
	
	* ViewModel은 아키텍처에서 센터역할을 한다. 이 녀석은 business 로직을 관리하고 model과 view 사이에서 통신한다.
* MVVM은 다음과 같은 규칙을 따른다.
	* **Model**은 다른 클래스들이 데이터 변경에 대한 notification을 내보내더라도 이들과 직접 통신하지 않는다.
	* **View Model**은 **Model**과 통신하며 여기서의 데이터들을 **ViewController**로 내보낸다.
	* View Controller는 View 생명주기를 처리하고 데이터를 UI 구성요소에 바인딩 할 때만 **View Model** 및 **View**와 통신한다.
	* (MVC 패턴에서처럼) **View**는 이벤트에 대해서만 view controller를 인식한다.
* 여기서 의문이 생긴다. 그렇다면 View Model은 MVC에서의 View Controller가 하는 역할을 하는 놈인지? 그렇기도 하고 아니기도 하다.
* 문제는 View Controller에 자꾸 View를 자체를 컨트롤하지 않는 코드를 채우는 것이다. MVVM은 이 문제를 해결하기 위해서 View Controller와 View를 한데 묶었다. 그리고 단독으로 View를 컨트롤할 책임을 할당한다.
* MVVM 아키텍처의 또 다른 장점은 코드 테스트가 용이하다는 점이다. business 로직으로부터 view의 생명주기를 분리하기 때문에, view controller와 view 모두에 대해 명확하게 테스트 하는 것이 가능하다.
* view model은 표현부에서 완전히 분리되어있고, 필요시에 platfrom들 사이에서 재사용이 가능하다. 즉, 단순히 view와 view controller 쌍을 대체하는 것만으로도 iOs, macOs, tvOS에까지도 마이그레이션이 가능하다.

### 3. 뭐가 어디로 가는거쥬?

* 하지만 *모든 것*이 View Model 클래스로 간다고 가정하면 안된다. 사실 코드를 세심하게 분리하고 책임을 할당하는 것은 개발자에게 달린 것이다. 그러므로 데이터와 화면 사이의 두뇌 역할로써 View Model을 남겨놓아야 한다. 하지만 네트워킹, 네비게이션, 캐시, 그리고 이와 같은 역할을 하는 부분은 다른 클래스로 분리해야한다. (만약에 이런 별개 클래스들이 MVVM 카테고리에 속하지 않는다면 어떻게 작업하쥬? MVVM은 이런 상황에 대해 강제적인 규칙이 따로 없지만 아무튼 어떻게 하는지 여기서 가르쳐줄거임.)
* 소개할 방법 중 하나는 View Model이 init이나 추후의 생명주기동안 필요로 할 모든 객체를 삽입하는 것이다. 즉, 상태기반 API 클래스(stateful API class) 또는 지속계층객체(persistence layer object)와 같이 긴 수명을 가지는 객체를 View Model에서 다른 View Model로 전달할 수 있다. (다음 그림 참고)

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/23_MVVM%20with%20RxSwift/3.pass.png?raw=true" height = 250>

	* 이 장에서 다룰 예제 프로젝트인 **Tweetie**를 통해, 인앱 네비게이션(`Navigator`), 현재 로그인된 트위터 계정(TwitterAPI.AcountStatus) 등등을 전달하는 법을 확인해볼 수 있다. 
* 추가적으로 어떤 장점이 있을까? 제대로 사용하면 다음과 같이, 고전적인 MVC 보다 향상된 패턴을 얻을 수 있다.
	* View Controller의 유일한 책임은 view를 "컨트롤" 하는 것이다. MVVC는 RxSwift/RxCocoa와 특히 잘 어울리는데 이유는 observable들을 UI 구성요소와 **바인딩** 할 수 있는 것은 이러한 패턴에 대한 핵심 원동력이다.
	* View Model은 *Input* -> *Output* 패턴을 명확하게 따르기 때문에 주어진 input과 예상되는 output으로 테스트하기가 쉽다. (아래 그림 참고)

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/23_MVVM%20with%20RxSwift/4.%20inout.png?raw=true" height = 100>
		
	* 예상되는 viw controller 상태를 테스트 하기 위해 모의 view model을 생성하고 테스트 할 수 있다. 이 방법을 통해 view controller를 시각적으로 테스트 하는 것이 훨씬 쉬워진다. (아래 그림 참고)

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/23_MVVM%20with%20RxSwift/5.%20visualtest.png?raw=true" height = 130>
 
## B. Tweetie(예제)로 시작하기

* 이 장에서는 여러개의 플랫폼(macOS, iOS 등)을 지원하는 Tweetie라는 앱을 만들어 볼 것이다. 이는 사전에 정의된 사용자 목록을 통해 트윗을 보여주는 아주 간단한 트위터용 앱이다. 기본 상태로 이 책의 저자와 편집자들의 트위터 목록을 볼 수 있게 해 놓았다. 현업에서 macOS와 iOS를 타겟하여 MVVM 패턴을 사용할 때의 작업기준으로 풀어나갈 것이다.
* 예제를 통해 MVVM이 다음과 같은 점을 어떻게 명확하게 구분하는지에 대한 방법을 확인하게 될 것이다.
	* iOS용 UIKit을 사용하는 view controller 및 Cocoa를 사용하는 별도의 macOS 전용 view controller와 같이 UI와 관련이 있는 코드 및 플랫폼별 코드들
	* model 및 view model의 모든 코드와 같이 특정 플랫폼의 UI 프레임 워크에 의존하지 않기 때문에 그대로 재사용되는 코드

### 1. 프로젝트 구조

* 프로젝트를 둘러보면 다음과 같은 몇 개의 폴더를 확인할 수 있다.
	* **Common Classes**: `Reachability`, `UITableView`, `NSTableView`의 Rx extension 등과 같이 macOS와 iOS에서 공유할 코드들
	* **Data Entities**: Realm Mobile Database와 함께 디스크에 저장될 데이터 객체
	* **TwitterAPI**: Twitter의 JSON API에 요청을 보내기 위한 Twitter API 구현. `TwitterAccount`는 API에서 사용할 access token을 얻는 클래스다. `TwitterAPI`는 웹 JSON에 대한 인증 요청을 만든다.
	* **View Models**: 3개의 앱 view model이 있다. 하나는 이미 완전히 구현되어 있고, 나머지 두개를 예제를 통해 직접 채워나가게 될 것이다. 
	* **iOS Tweetie**: 스토리보드와 iOS view controller를 포함하는 iOS 버전의 Tweetie를 가지고 있다.
	* **Mac Tweetie**: 스토리보드와 asset, view controller를 포함하는 Mac 버전의 Tweetie를 가지고 있다.
	* **TweetieTests**: 테스트와 모의 객체들이 있는 곳
		* **참고**: 이 장의 challenge까지 다 풀어야만 테스트가 가능하다. 
* 목표는 앱을 완성하여 사용자가 목록의 모든 트잇들을 볼 수 있도록 하는 것이다. `네트워킹 층 완성` -> `view model 클래스` -> `2개의 view controller(iOS, macOS) 생성` 의 순서로 진행될 것이다. (아래 그림 참고)

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/23_MVVM%20with%20RxSwift/6.%20workflow.png?raw=true" height = 250>

### 2. Twitter API에 액세스하기

* 트위터 계정만들기 -> 친구추가 -> Twitter API 사용을 위한 작업 
* ~더이상의 자세한 설명은 스킵한다~

### 3. 네트워크 층 완성하기

* **TimelineFetcher.swift**의 `TimeLineFetcher` 클래스를 살펴보자. 이 녀석은 앱이 연결되있는 동안 가장 최근 트윗을 자동적으로 불러오는 역할을 한다. Rx 타이머를 통해 웹에서 JSON을 반복해서 계속 구독하는 방식으로, 아주 심플하게 구성되어있다. 
* `TimelineFetcher`는 두 개의 `convenience init`을 가지고 있다. 하나는 주어진 트위터 목록에서 트윗을 가져오기 위한 것이고, 다른 하나는 사용자 본인의 트윗을 가져오기 위한 것이다.
* 여기서는 웹 요청을 만들고 `Tweet` 객체에 응답을 매핑하는 코드를 작성할 것이다. 비슷한 작업을 이미 한 적 있기 때문에 이 부분에 대한 코드들은 **Tweet.swift**에 이미 작성해놓았다.
	* **참고**: 사람들은 MVVM 프로젝트에서 네트워킹을 어디에 추가해야하는지에 대해 자주 질문합니다. 그래서 우리는 이 장에서 네트워킹에 대해서 당신이 직접 추가할 수 있도록 구성했습니다. 네트워킹에 대해서 복잡하게 생각할 필요 없어요. 그냥 view model에 넣을 일반적인 클래스예요. 
* **TimelineFetcher.swift**에서 `init(accout:jsonProvider:)` 아랫부분에서 다음과 같은 코드를 찾자.

	```swift
	timeline = Observable<[Tweet]>.empty()
	```

* 이 코드를 다음의 코드로 대체하자.

	```swift
	// 1
	timeline = reachableTimerWithAccount
	    .withLatestFrom(feedCursor.asObservable(), resultSelector: { account, cursor in
	        return (account: account, cursor: cursor)
	    })
	    // 2
	    .flatMapLatest(jsonProvider)
	    .map(Tweet.unboxMany)
	    .share(replay: 1, scope: .whileConnected)
	```
	
	* 1) timer observable인 `reachableTimerWithAccount`와 `feedCursor`를 병합하였다. `feedCursor`는 지금은 아무 행동도 하지 않는다. 하지만 이 variable을 이용하여 트위터 타임라인에 현재 위치를 저장한 뒤 이미 가져온 트윗을 나타내게 될 것이다.
	* 2) 메소드 매개변수인 `jsonProvider`를 flatmapping 한다. `jsonProvider`는 `init`에 삽입된 클로저다. 각각의 convinience init은 서로 다른 API 지점에서의 불러오기를 지원한다. 따라서 `jsonProvider`를 삽입하는 것은 메인 초기화(`init(accout:jsonProvider:)`)에서 `if` 문이나 가지치기 로직을 짜지 않아도 되는, 손쉬운 방법이다.
		* `jsonProvider`는 `Observable<[JSONObject]>`를 반환한다. 따라서 다음에 할일은 `Observable<[Tweet]>`으로 매핑하는 것이다. 예제에서 제공된 `Tweet.unboxMany` 함수를 이용할 수 있다. 이 함수는 `JSON` 객체를 `Array<Tweet>`으로 변환해주는 역할을 한다.
		* 이 몇줄의 코드를 통해 이미 트윗을 불러올 준비는 다 끝났다. `timeline`은 public observable 이기 때문에 해당 view model은 가장 최근의 트윗 리스트에 액세스 할 것이다. 앱의 view model의 역할은 트윗들을 디스크에 저장하거나 앱의 UI로 drive하는데 사용되는게 전부다. `TimelineFetcher`는 트윗들을 간단히 불러오고 결과를 내보낸다.

		<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/23_MVVM%20with%20RxSwift/7.%20timelinefetcher.png?raw=true" height = 100>
	
* 이 구독이 반복해서 호출되면, 같은 트윗들을 계속해서 불러오지 않기 위해 현재 위치(또는 커서)를 저장할 필요가 있다. 이를 위해 하기의 코드를 추가하자.

	```swift
	timeline
	    .scan(.none, accumulator: TimelineFetcher.currentCursor)
	    .bind(to: feedCursor)
	    .disposed(by: bag)
	```
	
	* `feedCursor`는 `Variable<TimelineCursor>`에서 `TimelineFetcher`의 프로퍼티다.
	* `TimelineCursor`는 지금까지 불러온 가장 오래된 트윗과 가장 최근의 트윗의 ID들을 가지고 있는 custom struct다. 이 코드에서는 `scan`을 통해서 ID들을 트래킹 하고 있다. 
	* 새로운 트윗 묶음을 가지고 올 때마다 `feedCursor`의 값을 업데이트 하게 된다. 만약 타임라인 커서 업데이트에 대한 로직이 궁금하다면 `TimelineFetcher.currentCursor()`를 살펴보면 좋다.
		* **참고**: Twitter API에서 자세한 내용을 확인할 수 있기 때문에 이 책에서는 커서 로직에 대해서 자세히 다루지 않습니다. [관련 내용](http://bit.ly/2zLF7mx) 
* 프로젝트에는 네비게이션 클래스, 데이터 엔티티, 트위터 계정 액세스 클래스가 이미 구현되어있다. 또한 지금까지의 작업을 통해 네트워크 계층이 완성되었으므로 이 모든 것을 결합하여 사용자를 트위터에 로깅하고 일부 트윗들을 가져올 수 있다. 

### 4. View Model 추가 하기
 
* 여기서는 controller에 대해 신경쓸 필요 없다. **View Model** 폴더의 **ListTimelineViewModel.swift**를 열자. 이름에서 추측할 수 있듯이, 이 view model은 주어진 사용자 리스트의 트윗들을 긁어온다.
* 다음 3가지 섹션을 정의하기에 좋은 연습이 될 것이다. 
	* 1. **Init**: 모든 디팬던시*dependency* 삽입을 수행하는 하나 이상의 `inits`를 정의한다.
	* 2. **Input**: view controller가 input을 제공할 수 있게, 일반적인 변수들 또는 RxSwift subject들과 같은 public 프로퍼티들을 포함한다.
	* 3. **Output**: view model에 output을 제공하는 모든 프로퍼티(보통은 observable)를 포함한다. 이들은 보통 table/collection view에 drive할 객체의 목록이거나, view controller가 앱의 UI에 드라이브할 때 사용할 다른 타입의 데이터들이다. 

	<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/23_MVVM%20with%20RxSwift/8.%20view%20model.png?raw=true" height = 200>

* `ListTimelineViewModel`은 `fetcher` 프로퍼티를 가지는 자신의 `init` 내부에 이미 일부 코드가 구현되어 있다. `fetcher`는 트윗을 긁어오는 `TimelineFetcher`의 인스턴스다.

#### init

* 이제 해당 view model에 코드를 추가할 차례가 왔다. 먼저 다음과 같이 input도, output도 아닌 두개의 프로퍼티를 추가한다. 이 녀석들은 단순히 디팬던시를 삽입하는 것을 도와줄 것이다. 

	```swift
	let list: ListIdentifier
	let account: Driver<TwitterAccount.AccountStatus>
	```
	
* 이들은 상수이기 때문에 이들을 초기화할 수 있는 곳은 `init(account:list:apiType)` 밖에 없다. 다음과 같은 코드를 클래스 초기화 부분 **가장 상단**에 입력한다. 

	```swift
	self.account = account
	self.list = list
	```

#### input

* 이제 input 프로퍼티를 추가할 차례다. 이 클래스의 디팬던시는 이미 삽입했으니 어떤 프로퍼티가 추가적으로 필요할까? 삽입된 디팬던시와 `init`에 제공하는 매개변수는 초기화할 때 input을 제공할 수 있게 해준다. 다른 public 프로퍼티를 사용하면 언제든지 view model에 대한 input을 계속해서 제공할 수 있게 된다. 
* 예를 들어, 사용자가 데이터베이스를 검색할 수 있게 해주는 앱을 생각해보자. 우리는 검색 텍스트 필드와 view model의 input 프로퍼티를 바인드할 것이다. 검색할 용어가 변화함에 따라, view model은 데이터베이스를 검색할 것이고 그에 따라 output을 변경할 것이다. 그리고 해당 결과를 테이블 뷰에 바인딩하여 표시할 것이다.
* 이 예제의 view model은 `TimelineFetcher` 클래스를 멈추고 재개시킬 객체라는 유일한 input을 가지게 될 것이다. `TimelineFetcher`는 이미 `Variable<Bool>`을 사용하므로 view model에는 프록시 설정만 필요하다.
* 하기의 코드를 `// MARK: - Input:`이라 표시된 곳의 `ListTimelineViewModel`에 삽입하자.

	```swift
	var paused: Bool = false {
	    didSet {
	        fetcher.paused.value = paused
	    }
	}
	```
	
	* 이 프로퍼티는 fetcher 클래스의 `paused` 값을 set 하는 프록시다. 

#### output

* view model은 긁어온 트윗 목록과 로그인 상태를 내보내게 될 것이다. 긁어온 트윗 목록은 `Variable<Tweet>`의 형태로 Realm에서 불러올 것이다. 현재 사용자가 트위터에 로그인했는지 여부는 `Driver<Bool>`을 통해 `false` 또는 `true`를 방출하게 될 것이다.
* output 섹션에 다음의 두개의 프로퍼티를 삽입하자.

	```swift
	private(set) var tweets: Observable<(AnyRealmCollection<Tweet>, RealmChangeset?)>!
	private(set) var loggedIn: Driver<Bool>!
	``` 
	
	* `tweet`은 가장 최근의 `Tweet` 객체 목록을 가진다. 어떤 트윗도 로드되기 전 상태, 예를 들어 로그인 이전 단계에서 기본값은 `nil`이다. `loggedIn`은 추후에 초기화 할 `Driver`다. 
* 이제 `TimelineFetcher`의 결과를 구독할 수 있고, 트윗들을 Realm에 저장할 수 있다. 다음 코드를 `init(accout:list:apiType:)`에 추가하자.
	
	```swift
	fetcher.timeline
	    .subscribe(Realm.rx.add(update: true))
	    .disposed(by: bag)
	``` 
	
	* 이를 통해 `fetcher.timeline`타입의 `Observable<[Tweet]>`을 구독하게 되고, 결과값(트윗 array)을 `Realm.rx.add(update:)`에 바인딩하였다. 
	* `Realm.rx.add`는 들어온 객체들을 앱의 기본 Realm 데이터베이스에 유지한다. 
* 지금까지 코드는 view model의 데이터 유입을 처리한다. 따라서 남은 작업은 view model의 output을 만드는 것이다. 다음 코드를 `bindOutput 메소드 내에 삽입하자.

	```swift
	guard let realm = try? Realm() else { return }
	tweets = Observable.changeset(from: realm.objects(Tweet.self))
	```
	
	* ~Ch.21 "RxRealm"에서 배운 것 처럼~, Realm의 `Results` 클래스를 통해 쉽게 observable sequence를 만들 수 있다. `tweet` observable을 view controller처럼 필요한 곳에 방출시킬 수 있다.
* 다음으로 할일은 `loggedIn` output 프로퍼티를 관리하는 것이다. 이 작업은 상당히 쉽다. `account`를 구독하고, 이 녀석의 요소(`true` 또는 `false`)를 매핑하는 것이다. 다음 코드를 `bindOutput`에 추가하자.
	
	```swift
	loggedIn = accout
	    .map { status in
	        switch status {
	        case .unavailable: return false
	        case .authorized: return true
	        }
	    }
	    .asDriver(onErrorJustReturn: false)
	```
	
* 여기까지가 view model에서 필요한 작업의 전부다! 모든 디팬던시들을 `init`에 삽입혰고, 다른 클래스가 input을 할 수 있도록 몇 가지 프로퍼티를 추가했으며, view model의 결과들을 다른 클래스에서 관찰할 수 있도록 public 프로퍼티를 추가해주었다. 
* 지금까지의 작업을 통해서 확인할 수 있듯이 view model은 자신의 초기화 함수에 삽입되지 않았다면, 어떠한 view controller, view 또는 또 다른 클래스들에 대해서도 알지 못한다. 

### 5. View Model 테스트 추가하기

~일단 skip~

### 6. iOS View Controller 추가하기

* 여기서는 작성한 view model의 output을 `ListTimelineViewController`내의 view들에 연결하는 코드를 작성할 것이다. 이 controller는 사용자 리스트의 트윗 조합들을 화면에 표시할 것이다. 
* **iOS Tweetie/View Controllers/List Timeline** 폴더 내에서 view controller와 iOS에 특화된 table cell view 파일들을 확인할 수 있다. **ListTimelineViewController.swift**를 열어 간단히 살펴보자. 
	* `ListTimelineViewController` 클래스에는 view model 프로퍼티와 `Navigator` 프로퍼티가 있다.
	* 두 클래스는 모두 `createWith(navigator:storyboard:viewModel)` 이라는 static factory 메소드를 통해 삽입된다. 
* 이제 두 세트의 셋업 코드를 view controller에 추가하게 될 것이다. 하나는 `viewDidLoad()`에 정적할당*static assignments* 될 것이고, 다른 하나는 `bindUI()`내에서 view model과 UI를 바인딩하는 코드가 될 것이다. 
* 다음의 코드를 `viewDidLoad()`내 `bindUI()`를 호출하기 **이전**에 추가하자. 
	
	```swift
	title = "@\(viewModel.list.username)/\(viewModel.list.slug)"
	navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: nil, action: nil)
	```
	
	* 이 코드는 목록명의 타이틀과 네비게이션바 우상단 버튼을 셋팅하는 역할을 한다.
* 다음은 view model을 바인딩할 차래다. 다음 코드를 `bindUI()`내부에 삽입하자.

	```swift
	navigationItem.rightBarButtonItem!.rx.tap
	    .throttle(0.5, scheduler: MainScheduler.instance)
	    .subscribe(onNext: { [weak self] _ in
	        guard let this = self else { return }
	        this.navigator.show(segue: .listPeople(this.viewModel.account, this.viewModel.list), sender: this)
	    })
	    .disposed(by: bag)
	``` 
	
	* 우측 바 아이템 탭을 구독하면서, 더블 탭은 막는 코드를 작성하였다. 
	* 그리고 `navigator` 프로퍼티의 `show(seque:sender:)` 메소드를 호출하여 화면에 segue를 표시할 수 있도록 한다. segue는 선택된 사용자 목록에 있는 사람들을 보여주게 된다. 
	* `Navigator`는 요청한 화면을 띄우거나 내리는 것을 관리하는 녀석이다. 
* table view에 가장 최근의 트윗을 보여주기 위해 또 다른 바인딩 생성이 필요하다. 파일의 상단으로 이동하여 다음 라이브러리를 추가하자. 

```swift
import RxRealmDataSources
```  

* 그리고 `bindUI()`로 돌아가서 다음 코드를 추가하자.

	```swift
	let dataSource = RxTableViewRealmDataSource<Tweet>(cellIdentifier: "TweetCellView", cellType: TweetCellView.self) { cell, _, tweet in
	    cell.update(with: tweet)
	}
	```
	
	* `dataSource`는 table view data source로, 특히 table view를 Realm collection 변화를 방출하는 observable로 drive할 때 유용하다. 단 한 줄의 코드로 data source를 완전히 구성할 수 있다.
		* 1. `Tweet` 타입의 model을 셋팅한다.
		* 2. 그리고 `TweetCellView`를 cell의 idendifier로 설정한다.
		* 3. 각각의 셀이 화면에 나타나기 전 구성될 수 있도록하는 클로저를 완성하였다.

* 이제 data source를 view controller상 table view와 바인드 할 수 있다. 하기의 코드를 마지막 블록 아래에 추가하자.

	```swift
	viewModel.tweets
	    .bind(to: tableView.rx.realmChanges(dataSource))
	    .disposed(by: bag)
	```
	
	* 이로써 `viewModel.tweets`는 `realmChanges`와 바인딩되었고 기구성된 data source를 제공한다.
* 이 view controller에 해줄 마지막 바인딩 작업은 사용자의 트위터 로그인 여부에 따라서 메시지를 표시하거나 숨기는 역할을 위한 것이다. 다음 코드를 추가하자.

	```swift
	viewModel.loggedIn
	    .drive(messageView.rx.isHidden)
	    .disposed(by: bag)
	```
	
	* 이 바인딩은 현재 `loggedIn`값에 기반한 `messageView.isHidden` 토글이 된다.

### 7. macOS View Controller 추가하기

~skip~ 

## C. Challenges
### 1. Challenge 1: members list내의 "Loading..." 토글하기

* 사용자목록 화면에서, *Loading...* 라벨이 항상 띄워져 있다. 이 라벨은 로딩상황에서는 현재상태 파악을 위한 좋은 방법이 되지만, 사실 서버에서 JSON 긁어오기를 하는 동안에만 보여주는 것이 정상이다. 
* 다음과 같은 과정을 통해서 해결할 수 있다. 
	* 먼저 **ListPeopleViewController.swift**를 연다. `bindUI()`에서 `viewModel.people`을 구독한다. 
	* 이를 `Driver`로 변환한 뒤, 요소들을 `true` 및 `false`로 매핑한다. 
	* `false`값은 `viewModel.people`이 `nil`일 때 방출된다. 
	* `messageView.rx.isHidden`을 `Driver<Bool>`결과값과 drive 한다. 

> A.
> 
> ```swift
> viewModel.people
>  	 .asDriver()
> 	 .map { $0 != nil }
> 	 .drive(messageView.rx.isHidden)
> 	 .disposed(by: bag)
> ```

### 2. Über challenge: 사용자 타임라인을 위해 View Model과 View 완성시키기

* 여전히 앱이 완전하지 않다. 사용자 목록상의 사용자를 선택하면 빈 view controller가 나타나는 것을 알 수 있다. 따라서 여기서의 과제는 특정 사용자를 선택하면 해당 사용자의 개인 트위터를 보여주는 것이다.
* 다음과 같은 과정을 통해서 해결할 수 있다.
	* **PersonTimelineViewModel.swift**를 열고 `tweet`이라는 이름의 프로퍼티를 찾아보자. 이 녀석을 `lazy var`로 변경하고 다음의 코드를 초기화하는데 사용하자.

		```swift
		public lazy var tweets: Driver<[Tweet]> = {
		    return self.fetcher.timeline
		        .asDriver(onErrorJustReturn: [])
		        .scan([], accumulator: { lastList, newList in
		            return newList + lastList
		        })
		}()
		```
	
		* 이 코드를 통해 `TimelineFetcher` 인스턴스를 구독하고 리스트의 모든 방출 트윗들을 취합할 수 있다. 
	* **PersonTimelineViewController.swift**의 `bindUI()`로 가서 `viewModel.tweets`에 두개의 구독을 추가하자.
		* 첫 번째 구독: view controller의 `rx.title`을 driver 한다. (`viewModel`에서의)사용자명과 함께 트윗들을 가져와 화면에 나타내기 전까지는 "None found"를 표시하도록 한다.
		* 두 번째 구독: 제공된 `createTweetsDataSource()`를 사용하여, data source 객체를 가진다. 그리고 트윗들을 `TweetSection`에 매핑한다. ~이 부분이 어려우면 RxDataSources 장을 살펴볼 것~ 그리고 table을 drive 한다.

> A.
> 
> ```swift
> func bindUI() {
> // 첫 번째 구독
> let titleWhenLoaded = "@\(viewModel.username)"
> viewModel.tweets
>     .map { tweets in
>         return tweets.count == 0 ? "None found" : titleWhenLoaded
> }
>     .drive(rx.title)
>     .disposed(by: bag)
>     
> // 두 번째 구독
> let dataSource = createTweetsDataSource()
> viewModel.tweets
>     .map { return [TweetSection(model: "Tweets", items: $0)]}
>     .drive(tableView.rx.items(dataSource: dataSource))
>     .disposed(by: bag)
> ```

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com