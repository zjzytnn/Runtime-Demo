# Runtime-Demo
	runtime，不同情况下的类方法的调用机制。
	以下的过程参考了这几篇博客：
	1、官方文档：Objective-C Runtime Programming Guide: 	https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008048-CH1-SW1
	2、struggle3g的消息转发： https://www.jianshu.com/p/2b61270cd038
	3、楚槟夕的OC-Runtime的理解和简单实用： https://www.jianshu.com/p/54f0311104c7
	4、利用runtime重写系统方法的两种方法： https://www.jianshu.com/p/61e293d8ed8d
	5、super和superclass： https://blog.csdn.net/weixin_33979363/article/details/88039872
	6、探秘runtime-runtime的应用： https://www.jianshu.com/p/4a22a39b69c5 
   	 探秘Runtime - Runtime Message Forward： https://www.jianshu.com/p/f313e8e32946
	7、ios源码解析-runtime篇： https://www.jianshu.com/p/de697d4a454f
	8、runtime - 子类动态实现父类的方法： https://www.jianshu.com/p/db66a28d117a
	9、Runtime-iOS运行时基础篇： https://www.jianshu.com/p/d4b55dae9a0d
	10、iOS Runtime 使用之 - 方法替换： https://www.jianshu.com/p/fed984c9f846
	11、iOS 中的runtime与消息转发： https://www.jianshu.com/p/45db86af7b60
	12、Runtime 方法替换 和 动态添加实例方法 结合使用： https://www.cnblogs.com/goodboy-heyang/p/5126557.html
	
	下面是详细问题
	1、如果有一个类C，实例化了一个对象c，调用[c methodA], 是怎么个调用流程？ 
	使用ojbc_msgSend函数实现。
	详细调用步骤：
	1）检测selector 是不是需要忽略的。比如 Mac OS X 开发，有了垃圾回收就不理会retain,release 这些函数了。
	2）检测target 是不是nil 对象。ObjC 的特性是允许对一个 nil对象执行任何一个方法不会 Crash，因为会被忽略掉。
	3）如果上面两个都过了，那就开始查找这个类的 IMP，先从 cache 里面找，若可以找得到就跳到对应的函数去执行。
	4）如果在cache里找不到就找一下方法列表methodLists。(此时子类重写的父类方法会被找到)
	5）如果methodLists找不到，就到超类的方法列表里寻找，一直找，直到找到NSObject类为止。(此时针对子类调用父类对象)
	6）如果还找不到，Runtime就提供了如下三种方法来处理：动态方法解析、消息接受者重定向、消息重定向。
	2、类C实现了methodA方法，是怎么调用？
	详细调用步骤参照上面1～5步，代码中以类B及其函数addB作为例子。
	3、类C没有实现methodA方法，会怎么样？
	详细调用步骤参照上面第6步。
	动态方法解析：代码中以类A及其函数addA作为例子。
	消息接受者重定向：代码中以类A调用addB作为例子。
	消息重定向：代码中以类A调用delB作为例子。
	4、如果是C的父类定义了methodA，类C没有重写这种方法又是怎么样的
	没有重写会调用父类的方法，如步骤3和4
	5、如果是在类C和类C的父类都定义了这个方法，又是怎么调用到父类的methodA方法的？
	步骤4位调用子类的methodA方法，代码中以子类B及其函数addA（重写父类A的addA方法）作为例子。
	想调用父类的methodA需要使用ojbc_msgSendSuper函数，代码中子类B的函数addB返回了父类的addA方法作为例子。
