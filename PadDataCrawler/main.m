//
//  main.m
//  PadDataCrawler
//
//  Created by darklinden on 14-10-29.
//  Copyright (c) 2014年 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#define PADPetNumMax    1701
#define SleepShortDelay 0.1
#define SleepLongDelay  5.0

#define kNum            @"Num"
#define kName           @"Name"
#define kStarLevel      @"StarLevel"
#define kProperty       @"Property"
#define kMaster         @"MasterProperty"
#define kVice           @"ViceProperty"
#define kHp             @"Hp"
#define kAtk            @"Atk"
#define kRe             @"Re"
#define kAwakeSkill     @"Awake"
#define kActiveSkill    @"ActiveSkill"
#define kLeaderSkill    @"LeaderSkill"

//#define work_path [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"pad"]
#define work_path [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"pad"]

void request_name_list();
void request_icon_list();
void parse_properties(BOOL reparse);
void parse_var(NSString *str, NSString **key, NSString **level, NSString **value);
BOOL parse_data(NSString *num, BOOL reparse);
void search_pet(NSDictionary *criteria);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
    
        request_name_list();
//        request_icon_list();
//        parse_properties(YES);
        
//        NSDictionary *dict = @{kProperty:@{kMaster: @"暗", kVice: @"木"}};
//        search_pet(dict);
        
//        parse_data(@"1001", YES);
    }
    return 0;
}

void request_name_list()
{
    NSString *html_path = [work_path stringByAppendingPathComponent:@"html"];
    [[NSFileManager defaultManager] createDirectoryAtPath:html_path withIntermediateDirectories:YES attributes:nil error:nil];
    
    int64_t index = 1;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    while (true) {
        
        @autoreleasepool {
            //http://pad.skyozora.com/pets/005
            //<title>005 - 普萊希 - プレシィ - Puzzle & Dragons 戰友系統及資訊網</title>
            
            NSString *num = nil;
            
            if (index < 100) {
                num = [NSString stringWithFormat:@"%03lld", index];
            }
            else {
                num = [NSString stringWithFormat:@"%lld", index];
            }
            
            NSString *file_path = [html_path stringByAppendingPathComponent:num];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:file_path]) {
                NSString *content = [NSString stringWithContentsOfFile:file_path encoding:NSUTF8StringEncoding error:nil];
                
                if ([content rangeOfString:[NSString stringWithFormat:@"<title>%@ -", num]].location != NSNotFound) {
                    
                    NSRange rs = [content rangeOfString:[NSString stringWithFormat:@"<title>%@ -", num]];
                    NSRange re = [content rangeOfString:@"- Puzzle & Dragons 戰友系統及資訊網</title>"];
                    NSString *tmp = [content substringWithRange:NSMakeRange(rs.location + rs.length, re.location - rs.location - rs.length)];
                    tmp = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    dict[num] = tmp;
                    
                    NSLog(@"Pet %@ exist, continue.", num);
                    
                    index++;
                    if (index > PADPetNumMax) {
                        break;
                    }
                    else {
                        continue;
                    }
                }
                else {
                    [[NSFileManager defaultManager] removeItemAtPath:file_path error:nil];
                    NSLog(@"Pet %@ file broken, rereading ...", num);
                }
            }
            else {
                NSLog(@"Reading %@ ...", num);
            }
            
            while (true) {
                
                NSString *petpage = [NSString stringWithFormat:@"http://pad.skyozora.com/pets/%@", num];
                
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:petpage]];
                [request setValue:@"Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.13) Gecko/20101206 Ubuntu/10.10 (maverick) Firefox/3.6.13" forHTTPHeaderField:@"User-Agent"];
                [request setTimeoutInterval:5.0];
                
                NSError *error = nil;
                NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
                
                if (error) {
                    NSLog(@"Pet %@ file download failed, redo ...", num);
                    sleep(SleepLongDelay);
                    continue;
                }
                
                NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                if ([content rangeOfString:@"<title>Puzzle & Dragons 戰友系統及資訊網</title>"].location != NSNotFound) {
                    NSLog(@"Pet %@ Not Found.", num);
                }
                else {
                    NSRange rs = [content rangeOfString:[NSString stringWithFormat:@"<title>%@ -", num]];
                    NSRange re = [content rangeOfString:@"- Puzzle & Dragons 戰友系統及資訊網</title>"];
                    NSString *tmp = [content substringWithRange:NSMakeRange(rs.location + rs.length, re.location - rs.location - rs.length)];
                    tmp = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    dict[num] = tmp;
                    
                    [data writeToFile:[html_path stringByAppendingPathComponent:num] atomically:YES];
                }
                
                break;
            }
            
            index++;
            sleep(SleepShortDelay);
            
            if (index > PADPetNumMax) {
                break;
            }
        }
    }
    
    NSString *index_path = [work_path stringByAppendingPathComponent:@"index.plist"];
    [[NSFileManager defaultManager] removeItemAtPath:index_path error:nil];
    [dict writeToFile:index_path atomically:YES];
}

void request_icon_list()
{
    NSString *html_folder_path = [work_path stringByAppendingPathComponent:@"html"];
    NSString *img_folder_path = [work_path stringByAppendingPathComponent:@"img"];
    [[NSFileManager defaultManager] createDirectoryAtPath:img_folder_path withIntermediateDirectories:YES attributes:nil error:nil];
    
    uint64_t index = 1;
    
    while (true) {
        
        NSString *num = nil;
        
        if (index < 100) {
            num = [NSString stringWithFormat:@"%03lld", index];
        }
        else {
            num = [NSString stringWithFormat:@"%lld", index];
        }
        
        NSString *file_path = [html_folder_path stringByAppendingPathComponent:num];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:file_path]) {
            NSString *content = [NSString stringWithContentsOfFile:file_path encoding:NSUTF8StringEncoding error:nil];
            
            if ([content rangeOfString:[NSString stringWithFormat:@"<title>%@ -", num]].location != NSNotFound) {
                
                NSString *img_path = [img_folder_path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", num]];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:img_path]) {
                    NSURL *url = [NSURL fileURLWithPath:img_path];
                    CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
                    
                    if (CGImageSourceGetCount(src)) {
                        NSLog(@"icon %@ has been downloaded.", num);
                        index++;
                        
                        if (index > PADPetNumMax) {
                            break;
                        }
                        else {
                            continue;
                        }
                    }
                }
                
                NSLog(@"icon %@ is downloading ...", num);
                
                while (true) {
                    NSString *str = [NSString stringWithFormat:@"http://pad.skyozora.com/images/pets/%@.png", num];
                    NSMutableURLRequest *requestimg = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:str]];
                    [requestimg setValue:@"Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.13) Gecko/20101206 Ubuntu/10.10 (maverick) Firefox/3.6.13" forHTTPHeaderField:@"User-Agent"];
                    [requestimg setTimeoutInterval:SleepLongDelay];
                    
                    NSError *error = nil;
                    NSData *dataimg = [NSURLConnection sendSynchronousRequest:requestimg returningResponse:nil error:&error];
                    
                    [dataimg writeToFile:img_path atomically:YES];
                    
                    
                    if (error) {
                        NSLog(@"icon %@ download failed, redo ...", num);
                        sleep(SleepLongDelay);
                    }
                    else {
                        NSURL *url = [NSURL fileURLWithPath:img_path];
                        CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
                        
                        if (CGImageSourceGetCount(src)) {
                            NSLog(@"icon %@ download success.", num);
                            break;
                        }
                        else {
                            NSLog(@"icon %@ download failed, redo ...", num);
                            sleep(SleepLongDelay);
                        }
                    }
                }
                
                index++;
                continue;
            }
            else {
                [[NSFileManager defaultManager] removeItemAtPath:file_path error:nil];
                NSLog(@"Pet %@ Not Found", num);
            }
        }
        else {
            NSLog(@"Pet %@ Not Found", num);
        }
        
        index++;
        
        if (index > PADPetNumMax) {
            break;
        }
    }
}

void parse_properties(BOOL reparse)
{
    uint64_t index = 1;
    
    while (true) {
        
        NSString *num = nil;
        
        if (index < 100) {
            num = [NSString stringWithFormat:@"%03lld", index];
        }
        else {
            num = [NSString stringWithFormat:@"%lld", index];
        }
        
        parse_data(num, reparse);
        
        index++;
        
        if (index > PADPetNumMax) {
            break;
        }
    }
}

void parse_var(NSString *str, NSString **key, NSString **level, NSString **value)
{
    NSString *tmp = [str copy];
    tmp = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (!tmp.length) {
        return;
    }
    
    NSRange rs, re;
    
    rs = [tmp rangeOfString:@"["];
    *key = [tmp substringToIndex:rs.location];
    
    re = [tmp rangeOfString:@"]"];
    *level = [tmp substringWithRange:NSMakeRange(rs.location + rs.length, re.location - rs.location - rs.length)];
    
    rs = [tmp rangeOfString:@"="];
    *value = [tmp substringFromIndex:rs.location + rs.length];
}

NSString *removeHTML(NSString *src)
{
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"<([^>]*)>" options:NSRegularExpressionCaseInsensitive error:nil];
    NSMutableString *regstr = [src mutableCopy];
    [reg replaceMatchesInString:regstr options:NSMatchingReportProgress range:NSMakeRange(0, regstr.length) withTemplate:@""];
    return regstr;
}

BOOL save_skill(NSString *key, NSString *skill_name)
{
    NSLog(@"save %@ skill: %@", key, skill_name);
    
    NSString *skill_folder = [work_path stringByAppendingPathComponent:@"skill"];
    NSString *key_folder = [skill_folder stringByAppendingPathComponent:key];
    [[NSFileManager defaultManager] createDirectoryAtPath:key_folder withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *skill_path = [key_folder stringByAppendingPathComponent:[skill_name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:skill_path]) {
        NSString *content = [NSString stringWithContentsOfFile:skill_path encoding:NSUTF8StringEncoding error:nil];
        
        if ([content rangeOfString:[NSString stringWithFormat:@"<title>%@ -", skill_name]].location != NSNotFound) {
            NSLog(@"Skill file downloaded %@", skill_name);
            return YES;
        }
        else {
            [[NSFileManager defaultManager] removeItemAtPath:skill_path error:nil];
            NSLog(@"Skill file %@ Not Found", skill_name);
        }
    }
    
    NSString *skill_str = [[NSString stringWithFormat:@"http://pad.skyozora.com/skill/%@", skill_name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *skillrequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:skill_str]];
    [skillrequest setValue:@"Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.13) Gecko/20101206 Ubuntu/10.10 (maverick) Firefox/3.6.13" forHTTPHeaderField:@"User-Agent"];
    [skillrequest setTimeoutInterval:SleepLongDelay];
    
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:skillrequest returningResponse:nil error:&error];
    
    if (error) {
        return NO;
    }
    else {
        [data writeToFile:skill_path atomically:YES];
        return YES;
    }
}

BOOL parse_data(NSString *num, BOOL reparse)
{
    NSString *html_path = [work_path stringByAppendingPathComponent:@"html"];
    NSString *file_path = [html_path stringByAppendingPathComponent:num];
    NSString *plist_folder_path = [work_path stringByAppendingPathComponent:@"plist"];
    [[NSFileManager defaultManager] createDirectoryAtPath:plist_folder_path withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *plist_path = [plist_folder_path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", num]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:plist_path]) {
        if (reparse) {
            NSLog(@"Parse %@ data - file has been parsed, reparse.", num);
            [[NSFileManager defaultManager] removeItemAtPath:plist_path error:nil];
        }
        else {
            NSLog(@"Parse %@ data - file has been parsed.", num);
            return YES;
        }
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:file_path]) {
        NSLog(@"Parse %@ data failed - file not exist.", num);
        return NO;
    }
    
    NSLog(@"Parsing %@ ...", num);
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    dict[kNum] = num;
    
    NSString *content = [NSString stringWithContentsOfFile:file_path encoding:NSUTF8StringEncoding error:nil];
    
    NSRange rs, re;
    NSString *tmp;
    
    //get name
    rs = [content rangeOfString:[NSString stringWithFormat:@"<title>%@ - ", num]];
    re = [content rangeOfString:@" - Puzzle & Dragons 戰友系統及資訊網</title>"];
    if (rs.location != NSNotFound && re.location != NSNotFound) {
        NSString *name = [content substringWithRange:NSMakeRange(rs.location + rs.length, re.location - rs.location - rs.length)];
        dict[kName] = name;
    }
    
    NSMutableDictionary *pro = [NSMutableDictionary dictionary];
    
    //title="主屬性:
    rs = [content rangeOfString:@"title=\"主屬性:"];
    if (rs.location != NSNotFound) {
        re = [content rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(rs.location + rs.length, content.length - rs.location - rs.length)];
        tmp = [content substringWithRange:NSMakeRange(rs.location + rs.length, re.location - rs.location - rs.length)];
        
        pro[kMaster] = tmp;
    }
    
    //title="副屬性:
    rs = [content rangeOfString:@"title=\"副屬性:"];
    if (rs.location != NSNotFound) {
        re = [content rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(rs.location + rs.length, content.length - rs.location - rs.length)];
        tmp = [content substringWithRange:NSMakeRange(rs.location + rs.length, re.location - rs.location - rs.length)];
        pro[kVice] = tmp;
    }
    
    dict[kProperty] = pro;
    
    //star level ★
    re = [content rangeOfString:@"title=\"主屬性:"];
    if (re.location != NSNotFound) {
        rs = [content rangeOfString:@"★" options:NSBackwardsSearch range:NSMakeRange(0, re.location)];
        tmp = [content substringToIndex:rs.location + 1];
        
        int32_t level = 0;
        while (true) {
            NSString *single = [tmp substringFromIndex:tmp.length - 1];
            tmp = [tmp substringToIndex:tmp.length - 1];
            if ([single isEqualToString:@"★"]) {
                level++;
            }
            else {
                break;
            }
        }
        
        dict[kStarLevel] = [NSString stringWithFormat:@"%d", level];
    }
    
    //get level hp atk re function updateHP
    re = [content rangeOfString:@"function updateLV(element)"];
    rs = [content rangeOfString:@"hp[1]=" options:NSBackwardsSearch range:NSMakeRange(0, re.location)];
    
    tmp = [content substringWithRange:NSMakeRange(rs.location, re.location - rs.location)];
    NSArray *vars = [tmp componentsSeparatedByString:@";"];
    
    NSMutableDictionary *dict_hp = [NSMutableDictionary dictionary];
    NSMutableDictionary *dict_atk = [NSMutableDictionary dictionary];
    NSMutableDictionary *dict_re = [NSMutableDictionary dictionary];
    
    for (NSString *tmp in vars) {
        NSString *key = nil;
        NSString *level = 0;
        NSString *value = nil;
        
        parse_var(tmp, &key, &level, &value);
        
        if ([key isEqualToString:@"hp"]) {
            dict_hp[level] = value;
        }
        else if ([key isEqualToString:@"atk"]) {
            dict_atk[level] = value;
        }
        else if ([key isEqualToString:@"re"]) {
            dict_re[level] = value;
        }
    }
    
    dict[kHp] = dict_hp;
    dict[kAtk] = dict_atk;
    dict[kRe] = dict_re;
    
    //>主動技能 - <
    //<a href="skill/%E6%9A%97%E9%BB%92%E3%81%AE%E5%91%AA%E3%81%84">
    rs = [content rangeOfString:@">主動技能 - <"];
    rs = [content rangeOfString:@"<a href=\"skill/" options:NSCaseInsensitiveSearch range:NSMakeRange(rs.location, content.length - rs.location)];
    re = [content rangeOfString:@"\">" options:NSCaseInsensitiveSearch range:NSMakeRange(rs.location, content.length - rs.location)];
    
    tmp = [content substringWithRange:NSMakeRange(rs.location + @"<a href=\"".length, re.location - rs.location - @"<a href=\"".length)];
    
    tmp = [[tmp substringFromIndex:@"skill/".length] stringByRemovingPercentEncoding];
    
    dict[kActiveSkill] = tmp;
    
    //save skill html
    BOOL success = NO;
    while (true) {
        success = save_skill(@"active", tmp);
        if (!success) {
            sleep(SleepLongDelay);
        }
        else {
            break;
        }
    };
    
    //>隊長技能 - <
    //<a href="skill/%E6%9A%97%E9%BB%92%E3%81%AE%E5%91%AA%E3%81%84">
    rs = [content rangeOfString:@">隊長技能 - <"];
    rs = [content rangeOfString:@"<a href=\"skill/" options:NSCaseInsensitiveSearch range:NSMakeRange(rs.location, content.length - rs.location)];
    re = [content rangeOfString:@"\">" options:NSCaseInsensitiveSearch range:NSMakeRange(rs.location, content.length - rs.location)];
    
    tmp = [content substringWithRange:NSMakeRange(rs.location + @"<a href=\"".length, re.location - rs.location - @"<a href=\"".length)];
    
    tmp = [[tmp substringFromIndex:@"skill/".length] stringByRemovingPercentEncoding];
    
    dict[kLeaderSkill] = tmp;
    
    //save skill html
    success = NO;
    while (true) {
        success = save_skill(@"leader", tmp);
        if (!success) {
            sleep(SleepLongDelay);
        }
        else {
            break;
        }
    }
    
    //>覺醒技能<
    //>隊長技能 - <
    rs = [content rangeOfString:@">覺醒技能<"];
    if (rs.location != NSNotFound) {
        re = [content rangeOfString:@">隊長技能 - <"];
        tmp = [content substringWithRange:NSMakeRange(rs.location + rs.length - 1, re.location + 2 - rs.location - rs.length)];
        
        NSMutableArray *array = [NSMutableArray array];
        
        while (tmp.length) {
            NSRange rss = [tmp rangeOfString:@"<a href=\"skill/"];
            
            if (rss.location == NSNotFound) {
                break;
            }
            
            NSRange res = [tmp rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(rss.location + rss.length, tmp.length - rss.location - rss.length)];
            
            NSString *tmps = [tmp substringWithRange:NSMakeRange(rss.location + @"<a href=\"".length, res.location - rss.location - @"<a href=\"".length)];
            
            tmps = [[tmps substringFromIndex:@"skill/".length] stringByRemovingPercentEncoding];
            
            [array addObject:tmps];
            
            success = NO;
            while (true) {
                success = save_skill(@"awake", tmps);
                if (!success) {
                    sleep(SleepLongDelay);
                }
                else {
                    break;
                }
            }
            
            tmp = [tmp substringFromIndex:res.location + res.length];
        }
        
        dict[kAwakeSkill] = array;
    }
    
    [dict writeToFile:plist_path atomically:YES];
    
    NSLog(@"Parse %@ success.", num);
    
    return YES;
}

BOOL _match(NSObject *obj, NSObject *criteria)
{
    BOOL match = YES;
    
    if ([obj isKindOfClass:[NSString class]]
        && [criteria isKindOfClass:[NSString class]]) {
        return [(NSString *)criteria isEqualToString:(NSString *)obj];
    }
    else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict_criteria = (NSDictionary *)criteria;
        NSDictionary *dict_obj = (NSDictionary *)obj;
        
        for (NSString *key in dict_criteria) {
            if (dict_obj[key]) {
                match = _match(dict_obj[key], dict_criteria[key]);
                if (!match) {
                    break;
                }
            }
            else {
                match = NO;
                break;
            }
        }
    }
    else if ([obj isKindOfClass:[NSArray class]]) {
        NSArray *array_criteria = (NSArray *)criteria;
        NSArray *array_obj = (NSArray *)obj;
        
        int32_t match_count = 0;
        for (int32_t ic = 0; ic < array_criteria.count; ic++) {
            
            BOOL tmpmatch = NO;
            for (int32_t io = 0; io < array_obj.count; io++) {
                if (_match(array_obj[io], array_criteria[ic])) {
                    tmpmatch = YES;
                    break;
                }
            }
            
            if (tmpmatch) {
                match_count++;
            }
        }
        
        if (match_count == array_criteria.count) {
            match = YES;
        }
    }
    
    return match;
}

void search_pet(NSDictionary *criteria)
{
    NSString *plist_folder_path = [work_path stringByAppendingPathComponent:@"plist"];
    
    uint64_t index = 1;
    
    while (true) {
        
        NSString *num = nil;
        
        if (index < 100) {
            num = [NSString stringWithFormat:@"%03lld", index];
        }
        else {
            num = [NSString stringWithFormat:@"%lld", index];
        }
        
        NSString *plist_path = [plist_folder_path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", num]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:plist_path]) {
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plist_path];
            
            if (_match(dict, criteria)) {
                NSLog(@"%@ : %@", num, dict[kName]);
            }
        }
        
        index++;
        
        if (index > PADPetNumMax) {
            break;
        }
    }
    
}