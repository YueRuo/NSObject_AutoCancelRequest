# iOS如何在页面销毁时优雅的cancel网络请求  

大家都知道，当一个网络请求发出去之后，如果不管不顾，有可能出现以下情况：  
进入某个页面，做了某种操作（退出页面、切换某个tab等等）导致之前的请求变成无用请求，这时候有可能出现虽然页面已经销毁了，但是网络请求还在外面飞的情况，如果放任不管，那么这个请求既浪费流量，有浪费性能，尤其是在网络比较差时，一个超时的无用请求更让人不爽。这时候，我们最好的办法是cancel掉这些无用的请求。

###传统的cancel方式是这样的：  
1.在类里面需要持有请求对象  
`@property (strong/weak, nonatomic) XXRequest *xxrequest1;`  
属性具体用strong还是weak取决于你的网络层设计，有些网络层request是完全的临时变量，出了方法就直接销毁的需要用strong，有些设计则具有自持有的特性，请求结束前不会销毁的可以用weak。    
2.在请求发起的地方，赋值请求  

```
xxrequest1 = xxx;
self.xxrequest1 = xxrequest1;
[xxrequest1 start];
```

3.在需要销毁的地方，一般是本类的dealloc里面  

`[self.xxrequest1 cancel];`

可以看到为了cancel一个request，我们的请求对象到处都是，如果再来几个请求，那处理起来就更恶心了。。  

有没有什么方式可以让我们省心省力呢？  

---

###目标：  
我们希望可以控制一部分请求，在页面销毁、manager释放等时机，自动的cancel掉我们发出去的请求，而不需要我们手动到处去写上面这种到处都是代码  

###方案：  
监听类的dealloc方法调用，当dealloc执行时，顺带着执行下request的cancel方法  

很快，我们就发现了问题：  
ARC下不允许hook类的dealloc方法，所以hook是不行的。那还有别的方式可以知道一个类被dealloc了吗？  

其实我们可以采用一些变通的方案得到，我们知道associated绑定的属性，是可以根据绑定时的设置，在dealloc时自动释放的，所以我们可以利用这一点做到监听dealloc调用：  

1. 构建一个中间类A，该类在销毁执行dealloc时，顺便执行请求的cancel方法  
2. 通过associate绑定的方式，将销毁类绑定到任意执行类B上  
3. 这样，当执行类B销毁时，销毁内部的associate的属性时，我们就可以得到相应的执行时机。  


###下面给出核心代码：  
1. 创建用于cancel请求的类：

```
@interface YRWeakRequest : NSObject
@property (weak, nonatomic) id request;
@end
@implementation YRWeakRequest
@end
```

2.构建用于记录某类绑定所有请求的类

```
@interface YRDeallocRequests : NSObject
@property (strong, nonatomic) NSMutableArray<YRWeakRequest*> *weakRequests;
@property (strong, nonatomic) NSLock *lock;
@end
@implementation YRDeallocRequests
- (instancetype)init{
    if (self = [super init]) {
        _weakRequests = [NSMutableArray arrayWithCapacity:20];
        _lock = [[NSLock alloc]init];
    }
    return self;
}
- (void)addRequest:(YRWeakRequest*)request{
    if (!request||!request.request) {
        return;
    }
    [_lock lock];
    [self.weakRequests addObject:request];
    [_lock unlock];
}
- (void)clearDeallocRequest{
    [_lock lock];
    NSInteger count = self.weakRequests.count;
    for (NSInteger i=count-1; i>0; i--) {
        YRWeakRequest *weakRequest = self.weakRequests[i];
        if (!weakRequest.request) {
            [self.weakRequests removeObject:weakRequest];
        }
    }
    [_lock unlock];
}
- (void)dealloc{
    for (YRWeakRequest *weakRequest in self.weakRequests) {
        [weakRequest.request cancel];
    }
}
@end
```

3.对任意类绑定该中间类

```
@implementation NSObject (YRRequest)

- (YRDeallocRequests *)deallocRequests{
    YRDeallocRequests *requests = objc_getAssociatedObject(self, _cmd);
    if (!requests) {
        requests = [[YRDeallocRequests alloc]init];
        objc_setAssociatedObject(self, _cmd, requests, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return requests;
}

- (void)autoCancelRequestOnDealloc:(id)request{
    [[self deallocRequests] clearDeallocRequest];
    YRWeakRequest *weakRequest = [[YRWeakRequest alloc] init];
    weakRequest.request = request;
    [[self deallocRequests] addRequest:weakRequest];
}
@end
```

4.对外暴露的头文件

```
@interface NSObject (YRRequest)

/*!
 *	@brief  add request to auto cancel when obj dealloc
 *  @note   will call request's cancel method , so the request must have cancel method..
 */
- (void)autoCancelRequestOnDealloc:(id)request;

@end
```


---

怎么样，看头文件是不是觉得很简单，使用方式就很简单了，  
比如说我们需要在某个VC里，释放时自动cancel网络请求：  

```
//请求发起的地方：
xxrequest1 = xxx;
[xxrequest1 start];
[self autoCancelRequestOnDealloc:xxrequest1];
```

好了，从此不再担心该类销毁时请求乱飞了。  

---

###其他：  
1.我的实现类里面，默认调用的是cancel方法，所以理论上，所有带有cancel方法的request都可以直接用这个方法调用（如AFNetworking、NSURLSessionTask等等）  
2.有些人会说，我是用自己的网络层，自己封装的requset发起的请求，不调用cancel，自己封装的对象也会销毁的；我要提醒的是，有可能你自己封装的对象销毁了，但是其下层，无论对接的是AF还是系统的，又或者是其他的请求库，一定是具有自持有性质的，如果不这么说，风险在于数据返回前底层的请求就会销毁掉，一般不会有人这么设计的。  
3.例子中我绑定的是self，其实还可以绑定到任意对象上，比如某个类的内部属性等等，这样可以根据业务需求进一步控制请求的cancel时机  


