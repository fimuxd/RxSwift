# RxSwift <img src = "https://github.com/ReactiveX/RxSwift/raw/main/assets/RxSwift_Logo.png" width = 60  align = right> 
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fgjbae1212%2Fhit-counter)](https://github.com/fimuxd/RxSwift)
>드디어 얘기만 듣던 `RxSwift` 스터디를 시작합니다.

## Contents
* [Tools](https://github.com/fimuxd/RxSwift#tools)
* [Curriculum](https://github.com/fimuxd/RxSwift#curriculum)
* [Contributors](https://github.com/fimuxd/RxSwift#Contributors)
* [ContactMe](https://github.com/fimuxd/RxSwift#ContactMe)

## Tools
* 📕 RxSwift - Reactive Programming with Swift by Martin Todorov ([구매하기](https://store.raywenderlich.com/products/rxswift?_ga=2.88706715.1421367013.1516248812-515082446.1516248812))
* 🔨 Xcode 9 or Later

## Curriculum

* 총 5개의 Section과 24개의 Chapter로 구성되어 있습니다.

* 일단 한 Chapter 씩 차근차근히 읽어나갈 계획입니다. (goals: min 1 chapter/day)

* 각 Chapter 별로 Summary한 내용들을 기록할 계획입니다.

* 개인적인 스터디 + 추후 틈틈히 챙겨볼 handbook 목적입니다.

* **Section I: Getting Started with RxSwift**
  > | Ch# | Chapter Subject | Question | Note |
  > |:---:| :--- | :--- | :--- |
  > |1|[Hello RxSwift!](https://github.com/fimuxd/RxSwift/blob/master/Lectures/01_HelloRxSwift/Ch.1%20Hello%20RxSwift.md) | - | RxSwift 개요|
  > |2|[Observables](https://github.com/fimuxd/RxSwift/blob/master/Lectures/02_Observables/Ch2.%20Observables.md) | - | **관찰가능한. RxSwift의 심장**<p> just, of, from, subscribe.empty, never, range, dispose, create, deferred, single, completable, maybe, do, debug |
  > |3|[Subjects](https://github.com/fimuxd/RxSwift/blob/master/Lectures/03_Subjects/Ch3.%20Subjects.md) | [Relays & Variables](https://github.com/fimuxd/RxSwift/blob/master/Lectures/03_Subjects/Ch3.%20Homework.md) | **Observable이자 Observer 인 녀석**<p> PublishSubject, BehaviorSubject, RelaySubject, Variable|
  > |4|[Observables and Subjects in Practice](https://github.com/fimuxd/RxSwift/blob/master/Lectures/04_ObservablesAndSubjectsInPractice/Ch4.ObservablesAndSubjectsInPractice.md)| - | **실전 연습**<p>single, maybe, completable |

* **Section II: Operators and Best Practices**
  > | Ch# | Chapter Subject | Practice | Note |
  > |:---:| :--- | :---: | :--- |
  > |5|[Filtering Operators](https://github.com/fimuxd/RxSwift/blob/master/Lectures/05_Filtering%20Operators/Ch5.%20FilteringOperators.md)| - |**필터링 연산자**<p> ignoreElements, elementAt, filter, skip, skipWhile, skipUntil, take, takeWhile, enumerated, takeUntil, distinctUntilChanged|
  > |6|[Filtering Operators in Practice](https://github.com/fimuxd/RxSwift/blob/master/Lectures/06_Filtering%20Operators%20in%20Practice/Ch.6%20Filtering%20Operators%20in%20Practice.md)| - |**실전 연습**<p>share, takeLast, throttle|
  > |7|[Transforming Operators](https://github.com/fimuxd/RxSwift/blob/master/Lectures/07_Transforming%20Operators/CH7_TransformingOperators.md)| - |**변환 연산자**<p> toArray, map, enumerated, flatMap, flapMapLatest, materialize, dematerialize, unwrap|
  > |8|[Transforming Operators in Practice](https://github.com/fimuxd/RxSwift/blob/master/Lectures/08_Transforming%20Operators%20in%20Practice/Ch.8%20Transforming%20Operators%20in%20Practice.md)| - |**실전 연습**<p>GitHub API를 이용한 map/flatMap 집중 연습|
  > |9|[Combining Operators](https://github.com/fimuxd/RxSwift/blob/master/Lectures/09_Combining%20Operators/Ch9.CombiningOperators.md)| - |**결합 연산자**<p> startWith, concat, concatMap, merge, merge(maxConcurrent), combineLatest, zip, withLatestFrom, sample, amb, switchLatest, reduce, scan, |
  > |10|[Combining Operators in Practice](https://github.com/fimuxd/RxSwift/blob/master/Lectures/10_Combining%20Operators%20in%20Practice/Ch.10%20Combining%20Operators%20in%20Practice.md)| - |**실전 연습**<p>NASA EONET API를 이용한 concat/combineLatest/scan 연습|
  > |11|[Time Based Operators](https://github.com/fimuxd/RxSwift/blob/master/Lectures/11_Time%20Based%20Operators/Time%20Based%20Operators.md)| - |**시간 기반 연산자**<p> replay, replayAll, buffer, window, delaySubscription, interval, timer, timeout|

* **Section III: iOS Apps with RxCocoa**
  > | Ch# | Chapter Subject | Practice | Note |
  > |:---:| :--- | :---: | :--- |
  > |12|[Beginning RxCocoa](https://github.com/fimuxd/RxSwift/blob/master/Lectures/12_Beginning%20RxCocoa/Ch12.%20Beginning%20RxCocoa.md)| - |**초급 RxCocoa**<p> rx, bindTo, ControlProperty, Driver, share|
  > |13|[Intermediate RxCocoa](https://github.com/fimuxd/RxSwift/blob/master/Lectures/13_Intermediate%20RxCocoa/Ch13.Intermediate%20RxCocoa.md)| - |**고급 RxCocoa**<p> Signal|

* **Section IV: Intermediaate RxSwift/RxCocoa**
  > | Ch# | Chapter Subject | Practice | Note |
  > |:---:| :--- | :---: | :--- |
  > |14|[Error Handling in Practice](https://github.com/fimuxd/RxSwift/blob/master/Lectures/14_Error%20Handling%20in%20Practice/Ch.14%20Error%20Handling%20in%20Practice.md)| - |**에러처리**<p> catch, retry|
  > |15|Intro To Schedulers| - |추후 별도 스터디|
  > |16|~Testing with RxTest~| - |skip|
  > |17|[Creating Custom Reactive Extensions](https://github.com/fimuxd/RxSwift/blob/master/Lectures/17_Creating%20Custom%20Reactive%20Extensions/Ch.17%20Creating%20Custom%20Reactive%20Extensions.md)| - |extension Reactive where Base: B { }|

* **Section V: RxSwift Community Cookbook**
  > | Ch# | Chapter Subject | Practice | Note |
  > |:---:| :--- | :---: | :--- |
  > |18|~Table and collection views~| - |skip|
  > |19|~Action~| - |skip|
  > |20|~RxGesture~| - |skip|
  > |21|~RxRealm~| - |skip|
  > |22|~RxAlamofire~| - |skip|

* **Section VI: Putting it All Together**
  > | Ch# | Chapter Subject | Practice | Note |
  > |:---:| :--- | :---: | :--- |
  > |23|[MVVM with RxSwift](https://github.com/fimuxd/RxSwift/blob/master/Lectures/23_MVVM%20with%20RxSwift/Ch.23%20MVVM%20with%20RxSwift.md)|[Simple Practice](https://github.com/fimuxd/RxSwift/tree/master/Practices/RxSwiftPractice)|**MVVM 아키텍처**|
  > |24|Building a Complete RxSwfit App| - |추후 별도 스터디|

* **Etc** 

  > | Date         | Title                                                    | Description(Subject)                                         | Note                                                         |
  > | ------------ | -------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
  > | Mar 16, 2019 | [ConSalad; 3rd bowl meet the corns](https://consalad.io) | RxSwift 1도 몰으겟읍니다에서 시작하기<p>- 미지의 영역을 대하는 자세에 관하여 | [발표자료](https://github.com/fimuxd/RxSwift/blob/master/Etc/ConSalad_RxSwift1도몰으겟읍니다_박보영_20190316.pdf) |

## Contributors

> Rx 무식자인 저의 눈높이에 맞춰 가르쳐주시는 멘토분들입니다. 고맙습니다. 

* [studiogaram](https://github.com/studiogaram)
* [doohochang](https://github.com/doohochang)
* [surida](https://github.com/surida)
* [woollim](https://github.com/woollim)

## ContactMe
* 📱 +82 10.3316.1609
* 📧 me@boyoung.dev

***
***Life is a game. Play it :)***
