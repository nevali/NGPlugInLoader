#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#import "NGPlugInLoader.h"

int
main(int argc, char **argv)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NGPlugInLoader *loader;
	
	loader = [[NGPlugInLoader alloc] init];
	NSLog(@"%@", [loader searchPaths]);
	[loader setApplicationName:@"PlugInPathTool"];
	NSLog(@"%@", [loader searchPaths]);
	[loader setFrameworkWithIdentifier:@"com.nexgenta.NGPlugInLoader"];
	NSLog(@"%@", [loader searchPaths]);
	[loader release];
	
	[pool drain];
	return 0;
}
