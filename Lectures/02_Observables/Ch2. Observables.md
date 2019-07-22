# Ch.2 Observable

## A. Getting Started
* Let's study using the `RxSwiftPlayground.playground` file provided as an example.
* Instead of connecting directly to the `.playground` file, you can check` .playground` through the `.xcworkspace` file.
* `.xcworkspace`> In the` Sources` folder at the bottom of the `.playground` file, there is a` SupportCode.swift` file. Here is a helper method to see an example of what you need here:

```swift
public func example(of description: String, action: () -> Void) {
	print("\n--- Example of:", description, "---")
	action()
}
```


## B. Observable?
* Heart of Rx
* We will look at what Observable is, how to make it, and how to use it.
* `observable` =` observable sequence` = `sequence`: You will continue to see each word, which is all the same. (Everything is a sequence)
* The important thing is that all of **these are (asynchronous**).
* Observables continue to generate **events** for a period of time, and this process is usually expressed as **emitting**. 
* Each event can have a **value** such as a number or a custom instance, or it can recognize a **gesture** like a tab. 
* The best way to understand these concepts is to use marble diagrams. 
	* marble diagram ?: How to display the value according to the flow of time
	* Assuming that time flows from left to right
	* Good site to refer to: [RxMarbles](http://rxmarbles.com) 

## C. Life Cycle of Observable

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/02_Observables/1.%20marble.png?raw=true" height = 50>

* The Marble diagram at the top shows three components. 
* Observable is to release each element through the `next` event described above.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/02_Observables/2.%20lifecycle1.png?raw=true" height = 50>

* This Observable is fully terminated after releasing three tap events. This is referred to as the `completed` event.

<img src = "https://github.com/fimuxd/RxSwift/blob/master/Lectures/02_Observables/3.%20lifecycle2.png?raw=true" height = 50>

* In this marble diagram, an error occurs unlike the above examples.
* There is no difference in terms of the Observable being completely shut down, but the exit from the `error` event

> In short, 
>
> * Observable can continue to fire `next` events with some components.
> * Observable can be terminated completely by issuing an `error` event.
>
> * Observable can be terminated completely by emitting a `complete` event.

* Let's look at the RxSwift source code example. In the example, these events are represented in an enum case.

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
	* Here you can see that `.next` events have any` Element` instances.
	* The `.error` event has a` Swift.Error` instance.
	* The `completed` event simply ends the event without any instances. 


## D. Create Observable

* Let's add the code below to `RxSwift.playground`.

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
	* What to do with this code
		* i) Define the Int constant to use in the next example
		* ii) Create an Observable sequence of type `Int` through the` just` method using `one` integer
	* `just` is a type method of` Observable`. As you can guess from the name, create an Observable sequence that contains only one element.
		* If what I understand is correct, the `observable` in the above code will shuffle`1`! I will.
	* Rx has ***operator*** (operator) so you can use it
* Let's add the following code at the bottom of the above code.

	```swift
	let observable2 = Observable.of(one, two, three)
	```  
	* The type of `observable2` is `Observable <Int>`
	* The `.of` operator creates an `Observable` sequence through type inference of the given values.
	* So, if you want to make an array an observable array, you can put the array into the `.of` operator.
	* [Check Marble diagram](http://rxmarbles.com/#of)

* Let's add the following code.

	```swift
	let observable3 = Observable.of([one, two, three])
	```
	* The type of `observable3` is `Observable <[Int]>`
	* This will cause `[1,2,3]` to be a single element, just like the `just` operator.

* Another operator that can create `Observable` is` from`.
	```swift
	let observable4 = Observable.from([one, two, three])
	``` 
	* The type of `observable4` is` Observable <Int> `
	* The `from` operator emits each element of a regular array
	* The `from` operator ***takes only array.***
	* [Check Marble diagram](http://rxmarbles.com/#from)

## E. Observable subscriptions

> Tip: The fact subscription is only a translation of *subscribing* in a dictionary. So, I asked you what exactly it means. In fact, if you ask what the *subscribing* means for each case, you can give a clear answer, but to understand just what *obscribable* means in Observable, You have to accumulate that feeling through your experience. So, I will try to translate the contents described in the book like the contents of the bottom. And after reading over time, I think there will be a lot of things to edit.

* If you are an iOS developer, you will be familiar with `NotificationCenter`. The example at the bottom shows the observer of the `UIKeyboardDidChangeFrame` notification using the closure syntax.

	```swift
	let observer = NotificationCenter.default.addObserver(
		forName: .UIKeyboardDidChangeFrame,
		object: nil,
		queue: nil
	) { notification in
		// Handle receiving notification
	}
	```
	* Subscribing to Observable of RxSwift is similar to the above method.
		* When you want to subscribe to Observable, you declare subscribe!
		* So use `subscribe ()` instead of `addObserver ()`.
		* However, if the above code was only available in the `.default` singleton instance, this is not the case for Rx's Observable.
* **(important)** Observable is actually just a sequence definition. **Observable does not send any events until it is a subscriber, ie subscribed** Just definitions.
* The Observable implementation is very similar to the `.next ()` implementation in the Swift native library loop.

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
	* Observable subscriptions are simpler than this.
	* You can add a handler for each event type emitted by Observable.
	* Observable will emit `.next`,` .error`, and `.completed` events again.
		* `.next` will pass the emitted elements through the handler,
		* `.error` should have an error instance

### 1. .subscribe()
* Let's add the code below to `RxSwift.playground`.

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
	* `.subscribe` has an escaping closure and has an` Int` type of `Event`. There is no return value for escaping (Void) and `.subscribe` returns` Disposable` (to be learned soon).
	* Looking at the printed values, Observable
		* i) I have released a `.next` event for each element.
		* ii) Finally released `.completed`.
	* Using Observable, in most cases Observable will be most interested in the elements emitted by the `.next` event.

### 2. .subscribe(onNext:)
* If we change the above code as follows,

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
	* Because it is a very common pattern, RxSwift has abbreviations for this part.
	* In other words, there is a `subscribe` operator for each event that Observable emits, such as `.next`, `.error`, and` .completed`.
* If you change the above code to look like this,

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
	* The `.onNext` closure will only handle` .next` events as arguments, and ignore all others.

### 2. .empty()
* Until now, we have only created an Observable with one or more elements. So what happens to Observable, which has no elements (count = 0)? `.completed` event through the` empty` operator.

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
	* Observable must be defined as a specific type.
	* In this case, you have to explicitly define the type because there is no type reasoning (there is no element to have), so `Void` will be a very appropriate type. 
	* If you go through each number in the annotation,
		* 1) Handles `.next` events.
		* 2) The `.completed` event has no elements, so it simply prints the message.
	* So what's the use of the alternative `empty` Observable? 
		* You want to return an Observable that can be immediately terminated.
		* If you intend to return an Observable with a value of zero

### 3. .never()
* Contrary to `empty` there is a` never` operator.

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
	* This does not even print `Completed`.
	* How can you tell if this code works? This part [Challenges](https://github.com/fimuxd/RxSwift/blob/master/Lectures/02_Observables/Ch2.%20Observables.md#1-부수작용-구현해보기-do-연산자) Let's take a look at the section.

### 4. .range()

* Consider the following code.

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
	* If you look at one by one,
		* 1) Use the `range` operator to create an Observable with values from `start` to `count`.
		* 2) Compute and output the nth Fibonacci number for each emitted element.
	* Later Ch7. In Transforming Operators, you learn how to transform emitted elements to better methods than the `onNext` handler.
	
## F. Disposing and closing
* **(Once again, important) Observable does not do anything until it receives a subscription.**
* This means that the subscription serves as a trigger to let Observable emit events
* Therefore, you can manually shut down the Observable by canceling the subscription to Observable (as opposed to thinking).

### 1. .dispose()
* Let's look at the code below.

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
	* If you look at one by one, 
		* 1) Create Observable of any string
		* 2) Try subscribing to this Observable. In this case, use `subscripe` to return` Disposable`.
		* 3) Prints each output event.
	* If you want to cancel your subscription here, you can call `dispose ()`. Event cancellation stops after canceling subscription or *dispose*.
    * Currently, there are only three elements in `observable`, so` Completed` is printed without calling `dispose ()`, but if the element is infinite, `dispose ()` is called to print `Completed`.

### 2. DisposeBag()
* Since it is not efficient to manage each subscription, you can use the `DisposedBag` type provided by RxSwift.
* `DisposeBag` has disposables (usually added via the` .disposed (by:) `method).
* disposable calls dispose () every time a dispose bag is about to be deallocated.
* Let's look at the code below.

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
	* If you look at one by one,
		* 1) Create a dispose bag
		* 2) Create observable
		* 3) And prints the event to be emitted.
		* 4) Add the returned value from `subscribe` to `disposeBag`.
	* These patterns are very common in the future. (subscribing to an observable and adding it immediately to the dispose bag)
* Why bother to do this every time?
	* If you add a dispose bag to a subscription or passively skip calling `dispose`, a memory leak will of course occur.
	* But do not worry. Swift will give you a warning whenever compiler does not write disposable ^^

### 3. .create(:)
* Just as we created Observable using the `.next` event, there is another way to do it with the` .create` operator.
* Let's look at the code below.

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

	* `create` is an escaping closure, escaping takes` AnyObserver` and returns `Disposable`.
	* Here, `AnyObserver` is a generic type that you can easily add to the Observable sequence. The added value is released to the subscriber.
	* If you look at one by one,
		* 1) Add a `.next` event to Observer. `onNext (_ :)` is a convenient way to write `on (.
		* 2) Add a `.completed` event to Observer. `onCompleted` is also a simplified version of` on (.completed) `
		* 3) Add an additional `.next` event.
		* 4) Returns disposable.
	* Here, the element of the second `.onNext` event,`? `, Is emitted to the subscriber. Would not it be? If you type `subscribe` as shown below,
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
		
		* Since the Observable has been terminated via `.onCompleted ()`, the second `onNext (_ :) 'is not emitted.
	* What if I add an error here? If you enter the following code before the example above, it ends with an error.
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
	* What happens if you do not emit both `.completed` or` .error` events and you do not add any subscriptions to disposeBag? (Annotate 5 or 2 and the last `. Disposed (by: disposeBag)`)
		* Two `onNext` elements` 1` and `?` Will be printed.
        * However, it does not release events for termination, nor does it do `.disposed (by: disposeBag)`, resulting in a waste of memory.
	
## G. Create observable factory
* Instead of creating an Observable (waiting for the subscriber!) to wait for the subscriber, there is a way to create an Obaservable factory that provides a new Observable item for each subscriber.
* Let's look at the code below.
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
	
	* If you look at one by one,
		* 1) Observable will generate a `Bool` value to return.
		* 2) Use the `deferred` operator to create` Int` factory Observable.
		* 3) `factory` toggles` flip` to subscribe (false> true)
		* 4) Return another Observable depending on the value of `flip`.
	* You can then print the value of the `factory` subscription repeated four times.
		* Each time you subscribe to `factory`, two Observables are output alternately.
	* Tip: The factory is like the concept we made in this book. The `.deferred` is a method that returns Observable. Like the `lazy var` in Swift's basic syntax, when subscribed,` .deferred` is executed and Observable is returned, which is the return value.

## H. Using Traits
* Trait can be selectively used with a narrower scope of Observable than the general Observable.
* Trait can be used to improve code readability.

### 1. Kinds
* There are three traits: `Single`, `Maybe`, and `Completable`.

#### Single
* emit `.success (value)` or `.error` events.
* `.success(value)` = `.next` + `.completed`
* Usage: One-time process that can be verified as success or failure (eg downloading data, loading data from disk)

#### Completable
* Only `.completed` or` .error` is emitted, and no other value is emitted.
* Use: When you want to make sure that the operation is done correctly (eg writing a file)

#### Maybe
* A mix of `Single` and` Completable`
* `success (value)`, `.completed`, and` .error` can all be emitted.
* Use: when the process is successful or fails and can print out the output value
* For more information, see Ch4. We can see more from now on, but for now, just a very simple example.
	* Suppose you use `single` to read some text from the` Copyright.txt` file in the `Resources` folder.

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
		
		* If you look at one by one,
			* 1) Create a dispose bag for later use
			* 2) An error that can occur when reading data from disk is defined through `Error` enum.
			* 3) Create a function that calls `text` from a file on disk and returns` single`
			* 4) Create and return `single`
		* Looking at the create closures in Annotation 4,
			* 4-1) The `subscribe` closure of the` create` method must return a disposable,
			* 4-2) It gets the path to the file name, and if it does not exist, it adds the error to `single` and returns disposable.
			* 4-3) If data is received from the file and the file can not be read, it is processed in the same way
			* 4-4) Check if there is an error when encoding the contents of a file into a String
		
		* You can run the function as shown below.
		
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
		* Let's make an error by making various changes such as changing the file name.

## Challenges
### 1. Implement side effects (do operator)
* The `never` operator in the previous example does not print anything. At that time, I put the observable into the dispose bag before subscribing, but if I add a value before that, I can not still print the message through the `onDisposed` handler of subscribe. 
* In this situation, there are useful operators that can perform separate tasks without affecting the Observable in action.
* The `do` operator allows you to add side effects. In other words, adding any work does not change the events that emit.
* `do` simply passes the event to the next operator.
* `do` has an` onSubscribe` handler that does not have `subscribe`. 
* The method that can use the `do` operator is` do (onNext: onError: onCompleted: onSubscribe: onDispose) `, which can provide a handler for any of these events. 

> Q. In the preceding `never` example, print using the` onSubscribe` handler of the `do` operator. Add a dispose bag to the subscription.
 
* A. 

	```swift
	example(of: "never") {
	    let observable = Observable<Any>.never()
	    
	    // 1.Create a dispose bag for the problem
	    let disposeBag = DisposeBag()
	    
	    // 2. Let's print out a message indicating that you subscribe to onSubscribe in do's just passing through
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
	    .disposed(by: disposeBag)			// 4. Dump it into the garbage bag made earlier
	}
	```

### 2. Taking debug information (debug operator)
* Problem # 1 is one of the ways that you can debug using the implemented Rx code, but there is a better way if you want to debug it.
* The `debug` operator prints all observable events.
* There may be many parameters, but the most effective is to put a string in the `debug` operator (eg debug ("any character"))

> Q. Print issue 1 through the `debug` operator.

* A.

```swift
example(of: "never") {
    let observable = Observable<Any>.never()
    let disposeBag = DisposeBag()			// 1. Also create a dispose bag
    
    observable
    	.debug("never 확인")			// 2. debug
    	.subscribe()					// 3. subscribe
    	.disposed(by: disposeBag) 	// 4. Fits in garbage bags
}

/* Prints:
2018-01-09 18:00:24.752: never 확인 -> subscribed
2018-01-09 18:00:24.754: never 확인 -> isDisposed
*/
```

***
##### Artwork/images/designs: from RxSwift: Reactive Programming in Swift book, available at http://www.raywenderlich.com
