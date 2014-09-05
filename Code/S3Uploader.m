//
//  S3Uploader.m
//  image-uploader
//
//  Created by Boris Bügling on 03/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <CommonCrypto/CommonCrypto.h>

#import "S3Uploader.h"

static NSString* const kS3Bucket    = @"";
static NSString* const kS3Key       = @"";
static NSString* const kS3Secret    = @"";

@interface S3Uploader ()

@property (nonatomic) NSURL* baseURL;

@property (nonatomic, copy) NSString* bucket;
@property (nonatomic, copy) NSString* key;
@property (nonatomic, copy) NSString* secret;

@end

#pragma mark -

@implementation S3Uploader

+(NSString *)computeHMACWithString:(NSString *)data secret:(NSString *)key {
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];

    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];

    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);

    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    return [HMAC base64EncodedStringWithOptions:0];
}

+(NSString*)rfc2822date {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
    return [dateFormatter stringFromDate:[NSDate date]];
}

+(instancetype)sharedUploader {
    static dispatch_once_t once;
    static S3Uploader *sharedUploader;
    dispatch_once(&once, ^ {
        sharedUploader = [[S3Uploader alloc] initWithBucket:kS3Bucket key:kS3Key secret:kS3Secret];
    });
    return sharedUploader;
}

#pragma mark -

-(instancetype)initWithBucket:(NSString*)bucket key:(NSString*)key secret:(NSString*)secret {
    self = [super init];
    if (self) {
        self.bucket = bucket;
        self.key = key;
        self.secret = secret;

        self.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.s3.amazonaws.com",
                                             self.bucket]];
    }
    return self;
}

-(void)uploadFileWithData:(NSData *)data
        completionHandler:(BBUFileUploadHandler)handler
          progressHandler:(BBUProgressHandler)progressHandler {
    NSParameterAssert(data);
    NSParameterAssert(handler);

    NSString* contentType = @"image/jpeg";
    NSString* fileName = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"jpg"];
    NSString* resourceName = [NSString stringWithFormat:@"/%@/%@", self.bucket, fileName];

    NSString* dateString = [[self class] rfc2822date];
    NSString* stringToSign = [NSString stringWithFormat:@"PUT\n\n%@\n%@\n%@", contentType, dateString,
                              resourceName];
    NSString* signature = [[self class] computeHMACWithString:stringToSign secret:self.secret];
    NSString* authorization = [NSString stringWithFormat:@"AWS %@:%@", self.key, signature];

    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{ @"Host": self.baseURL.host,
                                                    @"Date": dateString,
                                                    @"Content-Type": contentType,
                                                    @"Authorization": authorization };
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfiguration];

    NSURLSessionUploadTask* task = [session uploadTaskWithRequest:[NSURLRequest requestWithURL:[self.baseURL URLByAppendingPathComponent:fileName]] fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data) {
            handler(nil, error);
            return;
        }

        NSLog(@"Foo");
    }];

    [task resume];
}

#if TARGET_OS_IPHONE
-(void)uploadImage:(UIImage *)image
 completionHandler:(BBUFileUploadHandler)handler
   progressHandler:(BBUProgressHandler)progressHandler {
    NSData* data = UIImageJPEGRepresentation(image, 1.0);
#else
    -(void)uploadImage:(NSImage *)image
completionHandler:(BBUFileUploadHandler)handler
progressHandler:(BBUProgressHandler)progressHandler {
    NSData *data = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:data];
    NSDictionary *imageProperties = @{ NSImageCompressionFactor: @(1.0) };
    data = [imageRep representationUsingType:NSJPEGFileType properties:imageProperties];
#endif
    [self uploadFileWithData:data completionHandler:handler progressHandler:progressHandler];
}

@end