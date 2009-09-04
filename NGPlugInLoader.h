/*
 * Copyright (c) 2009 Mo McRoberts.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 3. The names of the author(s) of this software may not be used to endorse
 * or promote products derived from this software without specific prior
 * written permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * AUTHORS OF THIS SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef NGPLUGINLOADER_NGPLUGINLOADER_H_
# define NGPLUGINLOADER_NGPLUGINLOADER_H_ 1

#import <Foundation/Foundation.h>

# ifdef NGPLUGINLOADER_INTERNAL_
#  define NGPLUGINLOADER_CONST_EXTERN_ATTRIBUTE_
# else
#  define NGPLUGINLOADER_CONST_EXTERN_ATTRIBUTE_ __attribute__((weak_import))
# endif


# if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5

@protocol NGPlugInLoaderDelegate
@optional
- (BOOL)plugInShouldLoad:(NSBundle *)plugIn;
- (void)plugInDidLoad:(NSNotification *)notificiation;
@end

# else

@interface NSObject(NGPlugInLoaderDelegate)
- (BOOL)plugInShouldLoad:(NSBundle *)plugIn;
@end

@interface NSObject(NGPlugInLoaderNotifications)
- (void)plugInDidLoad:(NSNotification *)notificiation;
@end

#endif

@interface NGPlugInLoader : NSObject {
	id delegate;
	NSString *applicationName;
	NSString *bundleExtension;	
	NSString *mainBundlePlugInsPath;
	NSArray *localPaths;
	NSArray *perDomainPaths;
	NSArray *extraPaths;
}

+ (id)plugInLoader;
+ (id)plugInLoaderWithExtension:(NSString *)extension;

- (id)init;
- (id)initWithExtension:(NSString *)extension;

- (BOOL)addPath:(NSString *)relativePath withinBundle:(NSBundle *)bundle;
- (BOOL)addPath:(NSString *)relativePath withinBundleWithIdentifier:(NSString *)bundle;
- (BOOL)addBuiltInPlugInsFolderWithinBundle:(NSBundle *)bundle;
- (BOOL)addBuiltInPlugInsFolderWithinBundleWithIdentifier:(NSString *)bundle;

- (BOOL)addPath:(NSString *)relativePath withinDirectory:(NSSearchPathDirectory)dir;
- (BOOL)addPath:(NSString *)relativePath withinDirectory:(NSSearchPathDirectory)dir inDomains:(NSSearchPathDomainMask)mask;

- (void)addPath:(NSString *)path;

- (void)setApplicationName:(NSString *)appName;
- (void)setMainBundlePlugInsPath:(NSString *)path;

- (NSArray *)searchPath;

- (unsigned int)loadPlugIns;

# if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 
- (id<NGPlugInLoaderDelegate>)delegate;
- (void)setDelegate:(id<NGPlugInLoaderDelegate>)delegate;
# else
- (id)delegate;
- (void)setDelegate:(id)delegate;
#endif

@end

extern NSString *const NGPlugInLoaderPlugInDidLoadNotification NGPLUGINLOADER_CONST_EXTERN_ATTRIBUTE_;

#endif /*!NGPLUGINLOADER_NGPLUGINLOADER_H_*/
