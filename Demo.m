//
//  Demo.m
//  runtime plus
//
//  Created by yutingzheng on 2019/7/8.
//  Copyright © 2019 yutingzheng. All rights reserved.
//

#import "Demo.h"
#import <objc/message.h>
#import <objc/runtime.h>
#pragma GCC diagnostic ignored "-Wundeclared-selector"

@implementation Demo

+ (void)createClass{
    //创建A类
    Class A = objc_allocateClassPair([NSObject class], "A", 0);
    //成员方法
    //class_addMethod(A, @selector(addA:), (IMP)addA, "l@:l");
    //注册A类
    objc_registerClassPair(A);
    
    //修改A类的resolveInstanceMethod方法
    Method resolveClassMethod = class_getClassMethod(A, @selector(resolveInstanceMethod:));
    method_setImplementation(resolveClassMethod, class_getMethodImplementation(object_getClass(self), @selector(resolveInstanceMethod:)));
    
    //类方法不能通过这种方式添加？
//     class_addMethod(A, @selector(resolveInstanceMethod:), (IMP)method_getImplementation(class_getClassMethod([self class], @selector(resolveInstanceMethod:))), "B:");
    
    class_addMethod(A, @selector(forwardingTargetForSelector:), (IMP)method_getImplementation(class_getInstanceMethod([self class], @selector(forwardingTargetForSelector:))), "@:");
    
    class_addMethod(A, @selector(methodSignatureForSelector:), (IMP)method_getImplementation(class_getInstanceMethod([self class], @selector(methodSignatureForSelector:))), "^NSMethodSignature:");
    
    class_addMethod(A, @selector(forwardInvocation:), (IMP)method_getImplementation(class_getInstanceMethod([self class], @selector(forwardInvocation:))), "v^NSMethodSignature");
    
    
    //创建B类
    Class B = objc_allocateClassPair(A, "B", 0);
    //成员方
    class_addMethod(B, @selector(addB:), (IMP)addB, "l@:l");
    class_addMethod(B, @selector(delB:), (IMP)delB, "l@:l");
    class_addMethod(B, @selector(addA:), imp_implementationWithBlock(^(){
        NSLog(@"子类B重写父类A的方法。");
    }), "v@:");
    //注册B类
    objc_registerClassPair(B);
    
    //实例化A对象
    id a = [[A alloc] init];
    NSLog(@"类A对象a调用addA函数：");
    objc_msgSend(a, @selector(addA:), 1);
    NSLog(@"类A对象a调用addB函数：");
    objc_msgSend(a, @selector(addB:), 1);
    NSLog(@"类A对象a调用delB函数：");
    objc_msgSend(a, @selector(delB:), 1);
    
    //实例化B对象
    id b = [[B alloc] init];
    NSLog(@"类B对象b调用addA函数：");
    objc_msgSend(b, @selector(addB:), 1);
    NSLog(@"类B对象b调用addA函数：");
    objc_msgSend(b, @selector(addA:), 1);
    //[a performSelector:@selector(addA:) withObject:@"1"];
}

//修改resolveInstacnMethod
//cache和方法列表没有找到时，动态添加方法实现的机会
//这里应该是在if中写YES，外面返回super 方法，但是有一次的函数参数传进来不正确，调用了父类函数，陷入了死循环
+ (BOOL)resolveInstanceMethod:(SEL)sel{
    if(sel == @selector(addA:)){
        class_addMethod(objc_getClass("A"), sel, (IMP)addA, "l@:l");
        NSLog(@"动态方法解析addA");
        return YES;
    }
    else if(sel == @selector(addB:)){
        NSLog(@"动态方法解析addB");
        return YES;
    }
    else if(sel == @selector(delB:)){
        NSLog(@"动态方法解析delB");
        return YES;
    }
    return YES;
}

//重定向实例方法：返回类的实例
//动态添加方法返回NO
- (id)forwardingTargetForSelector:(SEL)sel{
    if(sel == @selector(addB:)){
        NSLog(@"重定向消息接收者addB");
        return [[objc_getClass("B") alloc] init];
    }
    else if(sel == @selector(delB:)){
        NSLog(@"重定向消息接收者delB");
        return nil;
    }
    return [super forwardingTargetForSelector:sel];
}

//提供信息创建NSInvocation对象
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    NSLog(@"提供信息创建NSInvocation对象");
    if([NSStringFromSelector(aSelector) isEqualToString:@"delB:"]){
        return [NSMethodSignature signatureWithObjCTypes:"l@:l"];
    }
    return [super methodSignatureForSelector:aSelector];
}

//消息重定向
- (void)forwardInvocation:(NSInvocation *)anInvocation{
    NSLog(@"消息重定向");
    //从anInvocation中获取消息
    SEL sel = anInvocation.selector;
    //判断实例是否可以响应sel
    id b = [[objc_getClass("B") alloc]init];
    if([b respondsToSelector:sel]){
        //可以响应，消息转发给其他对象处理
        [anInvocation invokeWithTarget:b];
    }
    else{
        //仍然无法响应，报错
        [self doesNotRecognizeSelector:sel];
    }
}

//实例方法addA
NSInteger addA(id self, SEL _lcmd, NSInteger arg){
    NSLog(@"我是addA");
    NSLog(@"%ld", arg * 2);
    return arg * 2;
}

//实例方法addB
NSInteger addB(id self, SEL _lcmd, NSInteger arg){
    NSLog(@"我是addB");
    NSLog(@"%ld", arg + 1);
    [self performSelector:@selector(addA:) withObject:@"1"];
    struct objc_super sup = {
        .receiver = self,
        .super_class = class_getSuperclass([self class])
    };
    return (NSInteger)objc_msgSendSuper(&sup, @selector(addA:), arg + 1);
}

//实例方法delB
NSInteger delB(id self, SEL _lcmd, NSInteger arg){
    NSLog(@"我是delB");
    NSLog(@"%ld", arg - 1);
    return arg - 1;
}

//类方法
//static NSInteger addA(id self, SEL _lcmd, NSInteger arg){
//    NSLog(@"我是静态addA");
//    NSLog(@"%ld", arg);
//    return arg * 2;
//}

//编译无法通过
//- (NSInteger)addA:(NSInteger) arg{
//    NSLog(@"我是addA");
//    NSLog(@"%ld", arg);
//    return arg;
//}

//参数传递有误
//NSInteger addA(NSInteger arg){
//    NSLog(@"我是addA");
//    NSLog(@"%ld", arg);
//    return arg * 2;
//}

//+ (BOOL)resolveInstanceMethod:(SEL)sel{
//    NSLog(@"动态方法解析");
//    return YES;
//}
//
//- (id)forwardingTargetForSelector:(SEL)sel{
//    NSLog(@"重定向消息接收者");
//    return nil;
//}
//
//- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
//    NSLog(@"提供信息创建NSInvocation对象");
//    if([NSStringFromSelector(aSelector) isEqualToString:@"addC:"]){
//        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
//    }
//    return [super methodSignatureForSelector:aSelector];
//}
//
////消息重定向
//- (void)forwardInvocation:(NSInvocation *)anInvocation{
//    NSLog(@"消息重定向");
//    //从anInvocation中获取消息
//    SEL sel = anInvocation.selector;
//    //判断实例是否可以响应sel
//    //id b = [[objc_getClass("B") alloc]init];
//    if([self respondsToSelector:sel]){
//        //可以响应，消息转发给其他对象处理
//        [anInvocation invokeWithTarget:self];
//    }
//    else{
//        //仍然无法响应，报错
//        [self doesNotRecognizeSelector:sel];
//    }
//}
@end


//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        //修改A类的resolveInstanceMethod方法
//        Method resolveClassMethod = class_getClassMethod(A, @selector(resolveInstanceMethod:));
//        method_setImplementation(resolveClassMethod, class_getMethodImplementation(object_getClass(self), @selector(fixResolveInstanceMethod:)));
//
//        //重定向A类的forwardingTargetForSelector方法
//        Method forwardingTargetForSelector = class_getInstanceMethod(A, @selector(forwardingTargetForSelector:));
//        IMP forwardingTargetForSelector_IMP = (IMP)method_getImplementation(class_getInstanceMethod([self class], @selector(fixForwardingTargetForSelector:)));
//        method_setImplementation(forwardingTargetForSelector, forwardingTargetForSelector_IMP);
//
//        //重定向A类的MethodSignatureForSelector方法
//        Method methodSignatureForSelector = class_getInstanceMethod(A, @selector(methodSignatureForSelector:));
//        IMP methodSignatureForSelector_IMP = (IMP)method_getImplementation(class_getInstanceMethod([self class], @selector(fixMethodSignatureForSelector:)));
//        method_setImplementation(methodSignatureForSelector, methodSignatureForSelector_IMP);
//
//        //重定向A类的forwardInvocation方法
//        Method forwardInvocation = class_getInstanceMethod(A, @selector(forwardInvocation:));
//        IMP forwardInvocation_IMP = (IMP)method_getImplementation(class_getInstanceMethod([self class], @selector(fixForwardInvocation:)));
//        method_setImplementation(forwardInvocation, forwardInvocation_IMP);
//    });

