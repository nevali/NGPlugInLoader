

#import <Foundation/Foundation.h>

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
	BOOL useDefaultSearchPaths;
	NSString *applicationName;
	NSString *frameworkIdentifier;
	NSString *bundleExtension;
	NSString *frameworkBundlePlugInsPath;
	NSString *frameworkPlugInsFolderPath;
	NSString *appBundlePlugInsPath;
	NSString *appPlugInsFolderPath;
	NSArray *searchPaths;
	NSArray *defaultSearchPaths;
}

+ (id)plugInLoader;
+ (id)plugInLoaderWithExtension:(NSString *)extension;

- (id)init;
- (id)initWithExtension:(NSString *)extension;

- (NSArray *)searchPaths;
- (void)addSearchPath:(NSString *)path;
- (void)setSearchPaths:(NSArray *)paths;
- (void)setSearchPaths:(NSArray *)paths replacingDefaults:(BOOL)replace;
- (void)setApplicationName:(NSString *)appName;
- (void)setFrameworkWithIdentifier:(NSString *)identifier;
- (void)setFrameworkWithBundle:(NSBundle *)bundle;

- (unsigned int)loadPlugIns;

# if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 
- (id<NGPlugInLoaderDelegate>)delegate;
- (void)setDelegate:(id<NGPlugInLoaderDelegate>)delegate;
# else
- (id)delegate;
- (void)setDelegate:(id)delegate;
#endif

@end

extern NSString *NGPlugInLoaderPlugInDidLoadNotification;
