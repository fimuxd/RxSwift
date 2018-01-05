# Ch.1 Hello RxSwift

## RxSwift?

‘RxSwift is a library for composing asynchronous and event-based code by using observable sequences and functional style operators, allowing for parameterized execution via schedulers.’

*By Marin Todorov. ‘RxSwift - Reactive Programming with Swift.’ iBooks.*

> ~무슨 말인지 잘 모르겠지만,~ 주목할만한 keywords: `observable(관찰가능한)`, `asynchronous(비동기)`, `functional(함수의)`, `via schedulers(스케줄러를 통해)`)

다시 표현하자면 이렇다고 한다.

**RxSwift는 '본질적'으로 코드가 '새로운 데이터에 반응'하고 '순차적으로 분리 된' 방식으로 처리함으로써 '비동기식' 프로그램 개발을 간소화합니다.**

## Cocoa and UIKit Asynchronous APIs

Apple은 iOS SDK 내에서 비동기식 코드를 작성할 수 있도록 다양한 API를 제공하고 있다. 주된 방법은 다음과 같다.

* Notification Center
* The delegate pattern
* Grand Central Dispatch(GCD)
* Closures

일반적으로 대부분의 클래스들은 비동기적으로 작업을 수행하고 모든 UI 구성요소들은 본질적으로 비동기적이다. 따라서 내가 어떤 앱 코드를 작성했을 때 정확히 매번 어떤 순서로 작동하는지 가정하는 것을 불가능하다. 결국 앱의 코드는 사용자 입력, 네트워크 활동 또는 기타 OS 이벤트와 같은 다양한 외부 요인에 따라 완전히 다른 순서로 실행될 수 있다. 

> 결국 문제는, Apple의 SDK내의 API를 통한 복합적인 비동기 코드는 부분별로 나눠서 쓰기 매우 어려울 수 밖에(또는 거의 추적불가능) 없다는 것 
 
 


## Asynchronous programming glossary
