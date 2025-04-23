// SafePredicate.m
#import "SafePredicate.h"

NSPredicate* _Nullable safePredicate(NSString* _Nonnull format) {

    NSPredicate *predicate = nil;
    
    @try {
        predicate = [NSPredicate predicateWithFormat:format];
    } @catch (NSException *exception) {
        NSLog(@"Failed to parse predicate: %@: %@", format, exception);
        // Return nil on failure
    }
    
    return predicate;

}