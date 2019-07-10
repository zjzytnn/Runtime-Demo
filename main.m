//
//  main.m
//  runtime plus
//
//  Created by yutingzheng on 2019/7/8.
//  Copyright © 2019 yutingzheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Demo.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        [Demo createClass];
        //id demo = [[Demo alloc] init];
        //[demo performSelector:@selector(addC:)];
    }
    return 0;
}

