//
//  ViewController.m
//  curlDemo
//
//  Created by Demo on 2022/3/9.
//

#import "ViewController.h"
#include "curl/curl.h"

@interface ViewController ()

@end

typedef struct _CURL_DOWNLOAD_OBJECT {
    long size;
    char *data;
} CURL_DOWNLOAD_OBJECT, *LPCURL_DOWNLOAD_OBJECT;

size_t curlCallback(char *data, size_t size, size_t count, void *userdata);
BOOL downloadUrl(const char *url, LPCURL_DOWNLOAD_OBJECT downloadObject);

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    const char *url = "https://www.baidu.com";
    NSLog(@"Starting the download of url %s", url);
    CURL_DOWNLOAD_OBJECT downloadObject;
    downloadObject.data = NULL;
    downloadObject.size = 0;
    downloadUrl(url, &downloadObject);
}

BOOL downloadUrl(const char *url, LPCURL_DOWNLOAD_OBJECT downloadObject) {
    CURL *curl = curl_easy_init();
    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, TRUE);
    curl_easy_setopt(curl, CURLOPT_FAILONERROR, TRUE);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, &curlCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, downloadObject);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, FALSE);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, FALSE);
    
    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
        NSLog(@"CURL failed with error code %d", res);
    }
    curl_easy_cleanup(curl);
    return res == CURLE_OK;
}

size_t curlCallback(char *data, size_t size, size_t count, void *userdata) {
    NSLog(@"Downloaded data size is %lu", size*count);
    
    LPCURL_DOWNLOAD_OBJECT downloadObject = (LPCURL_DOWNLOAD_OBJECT) userdata;
    long newSize = 0;
    long offset = 0;
    char *dataPtr;
    
    if (downloadObject->data == NULL){
        newSize = size * count * sizeof(const char);
        dataPtr = (char *)malloc(newSize);
    }else{
        newSize = downloadObject->size + (size * count * sizeof(const char));
        dataPtr = (char *)realloc(downloadObject->data, newSize);
        offset = downloadObject->size;
    }
    
    if (dataPtr == NULL) {//malloc or realloc failed
        if (downloadObject->data != NULL) {//realloc failed
            free(downloadObject->data);
            downloadObject->data = NULL;
            downloadObject->size = 0;
        }
        return 0; //this will abort the download
    }
    downloadObject->data = dataPtr;
    downloadObject->size = newSize;
    
    memcpy(downloadObject->data + offset, data, size * count * sizeof(const char));
    return size*count;
}

@end
