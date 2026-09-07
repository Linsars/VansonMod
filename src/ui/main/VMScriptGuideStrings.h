#ifndef VMScriptGuideStrings_h
#define VMScriptGuideStrings_h

#include <map>
#include <string>

static std::map<std::string, std::map<std::string, std::string>> kScriptGuideStrings = {
    
    {"tips_content", {
        {"en", "💡 <b>Tips:</b> Type suffixes use standard naming: signed integers (I8, I16, I32, I64), unsigned integers (U8, U16, U32, U64), floats (F32, F64). Types are case-insensitive. This document covers all VM available commands. Also compatible with h5gg syntax."},
        {"zh", "💡 <b>核心提示：</b> 类型后缀采用标准化命名：有符号整数 (I8, I16, I32, I64)、无符号整数 (U8, U16, U32, U64)、浮点数 (F32, F64)。类型不区分大小写。本文档涵盖VM所有可用指令，同时兼容 h5gg 语法。"},
    }},

    {"section_1", {
        {"en", "1. Exact Search"},
        {"zh", "1. 精确搜索 (Search)"},
    }},
    {"section_2", {
        {"en", "2. Refine Search"},
        {"zh", "2. 再次搜索 (Refine)"},
    }},
    {"section_3", {
        {"en", "3. Fuzzy Search"},
        {"zh", "3. 模糊搜索 (Fuzzy)"},
    }},
    {"section_4", {
        {"en", "4. Group Search"},
        {"zh", "4. 联合搜索 (Group)"},
    }},
    {"section_5", {
        {"en", "5. Nearby Search"},
        {"zh", "5. 临近搜索 (Nearby)"},
    }},
    {"section_6", {
        {"en", "6. Signature Search"},
        {"zh", "6. 特征码搜索 (Signature)"},
    }},
    {"section_7", {
        {"en", "7. Results Operations"},
        {"zh", "7. 结果操作 (Results)"},
    }},
    {"section_8", {
        {"en", "8. Memory I/O"},
        {"zh", "8. 地址读写 (Memory I/O)"},
    }},
    {"section_9", {
        {"en", "9. Module Info"},
        {"zh", "9. 模块信息 (Module Info)"},
    }},
    {"section_10", {
        {"en", "10. System Functions"},
        {"zh", "10. 系统功能 (System)"},
    }},
    {"section_11", {
        {"en", "11. Value Lock"},
        {"zh", "11. 数值锁定 (Lock)"},
    }},
    {"section_demo", {
        {"en", "Complete Example"},
        {"zh", "完整示例"},
    }},

    {"btn_copy", {
        {"en", "Copy"},
        {"zh", "复制"},
    }},
    {"btn_insert", {
        {"en", "Insert"},
        {"zh", "插入"},
    }},

    {"th_param", {
        {"en", "Param"},
        {"zh", "参数"},
    }},
    {"th_desc", {
        {"en", "Description"},
        {"zh", "说明"},
    }},

    {"card_results_title", {
        {"en", "Get & Modify Results"},
        {"zh", "结果获取与修改"},
    }},
    {"card_io_title", {
        {"en", "Direct Address Operations"},
        {"zh", "直接地址操作"},
    }},
    {"card_module_title", {
        {"en", "Process Modules"},
        {"zh", "进程模块"},
    }},
    {"card_sys_title", {
        {"en", "Utilities"},
        {"zh", "辅助功能"},
    }},
    {"card_lock_title", {
        {"en", "Lock & Unlock"},
        {"zh", "锁定与解锁"},
    }},
    {"card_demo_title", {
        {"en", "Single-Player Process Debug Example"},
        {"zh", "单机进程调试示例"},
    }},

    {"desc_search", {
        {"en", "Search for exact values within specified range, supports custom start/end addresses."},
        {"zh", "在指定范围内搜索精确数值，支持自定义起止地址。"},
    }},
    {"desc_refine", {
        {"en", "Filter existing results with various comparison modes."},
        {"zh", "在已有结果中进一步筛选，支持多种比对模式。"},
    }},
    {"desc_fuzzy", {
        {"en", "Initialize fuzzy search by taking memory snapshot, then use refine to filter changes."},
        {"zh", "初始化模糊搜索，记录当前内存快照，后续使用 refine 筛选变化。"},
    }},
    {"desc_group", {
        {"en", "Search multiple related values simultaneously. Supports mixed types, offset ranges, * / ? placeholders, and w:byte skips."},
        {"zh", "同时搜索多个关联数值，支持混合类型、偏移范围、* / ? 占位和 w:字节数跳过。"},
    }},
    {"desc_nearby", {
        {"en", "Search for other values near current results, useful for locating related data in structures."},
        {"zh", "在当前结果附近搜索其他数值，用于定位结构体内的关联数据。"},
    }},
    {"desc_signature", {
        {"en", "Locate memory addresses using hex patterns, supports ?? wildcard."},
        {"zh", "使用十六进制特征码定位内存地址，支持 ?? 通配符。"},
    }},
    {"desc_results", {
        {"en", "Get result count, result list, and batch modify."},
        {"zh", "获取搜索结果数量、结果列表，以及批量修改。"},
    }},
    {"desc_io", {
        {"en", "Perform precise read/write operations on specific memory addresses."},
        {"zh", "对指定内存地址进行精确的读取和写入操作。"},
    }},
    {"desc_module", {
        {"en", "Get all loaded modules and base addresses, set main module base."},
        {"zh", "获取当前进程的所有加载模块及基准地址，设置主模块基址。"},
    }},
    {"desc_system", {
        {"en", "Sleep, logging, toast notifications, float tolerance and other system functions."},
        {"zh", "延时、日志、提示、浮点容差等系统级功能。"},
    }},
    {"desc_lock", {
        {"en", "Lock search results by index or filter condition."},
        {"zh", "锁定搜索结果中的数值，支持按索引或过滤条件筛选。"},
    }},
    {"desc_demo", {
        {"en", "A complete memory debugging script example showing common workflow."},
        {"zh", "一个完整的内存调试脚本示例，展示常用工作流程。"},
    }},

    {"param_value", {
        {"en", "Value to search (string)"},
        {"zh", "要搜索的数值 (字符串)"},
    }},
    {"param_type", {
        {"en", "Data type: I8, I16, I32, I64, U8, U16, U32, U64, F32, F64"},
        {"zh", "数据类型: I8, I16, I32, I64, U8, U16, U32, U64, F32, F64"},
    }},
    {"param_from", {
        {"en", "Start address (optional)"},
        {"zh", "起始地址 (可选, 默认使用设置)"},
    }},
    {"param_to", {
        {"en", "End address (optional)"},
        {"zh", "结束地址 (可选, 默认使用设置)"},
    }},
    {"param_filter_value", {
        {"en", "Filter value"},
        {"zh", "筛选数值"},
    }},
    {"param_mode", {
        {"en", "Compare mode: eq(equal), gt(greater), lt(less), chg(changed), inc(increased by), dec(decreased by)"},
        {"zh", "比对模式: eq(等于), gt(大于), lt(小于), chg(变化), inc(增加了), dec(减少了)"},
    }},
    {"param_values_expr", {
        {"en", "Value expression, separated by semicolons or spaces. Supports value [type][::range], * / ?, type:*, and w:bytes."},
        {"zh", "数值表达式，用分号或空格分隔。支持 数值 [类型][::范围]、* / ?、类型:*、w:字节数。"},
    }},
    {"param_default_type", {
        {"en", "Default data type (used when type not specified)"},
        {"zh", "默认数据类型 (未指定类型时使用)"},
    }},
    {"param_range", {
        {"en", "Search range in bytes (default: 50)"},
        {"zh", "搜索范围 (字节数, 默认50)"},
    }},
    {"param_signature", {
        {"en", "Hex pattern, ?? for any byte"},
        {"zh", "十六进制特征码，?? 表示任意字节"},
    }},
    {"param_lock_value", {
        {"en", "Value to lock"},
        {"zh", "锁定的数值"},
    }},
    {"param_index_filter", {
        {"en", "lock uses index, lockAll uses filter"},
        {"zh", "lock用索引, lockAll用过滤条件"},
    }},

    {"comment_basic_search", {
        {"en", "// Basic search"},
        {"zh", "// 基础搜索"},
    }},
    {"comment_search_range", {
        {"en", "// Search with range"},
        {"zh", "// 指定范围搜索"},
    }},
    {"comment_exact_match", {
        {"en", "// Exact match"},
        {"zh", "// 精确匹配"},
    }},
    {"comment_value_increased", {
        {"en", "// Value increased by"},
        {"zh", "// 数值增加了"},
    }},
    {"comment_value_decreased", {
        {"en", "// Value decreased by"},
        {"zh", "// 数值减少了"},
    }},
    {"comment_value_changed", {
        {"en", "// Value changed"},
        {"zh", "// 数值变化了"},
    }},
    {"comment_greater_than", {
        {"en", "// Greater than"},
        {"zh", "// 大于某值"},
    }},
    {"comment_less_than", {
        {"en", "// Less than"},
        {"zh", "// 小于某值"},
    }},

    {"card_editall_adv_title", {
        {"en", "Advanced Batch Modify (editAll Filter Syntax)"},
        {"zh", "高级批量修改 (editAll 过滤语法)"},
    }},
    {"desc_editall_adv", {
        {"en", "The third parameter of vm.editAll supports complex filter combinations for precise control over which results to modify."},
        {"zh", "vm.editAll 第三个参数支持复杂的过滤条件组合，可精确控制修改哪些结果。"},
    }},
    {"th_syntax", {
        {"en", "Syntax"},
        {"zh", "语法"},
    }},
    {"th_example", {
        {"en", "Example"},
        {"zh", "示例"},
    }},
    {"filter_single_index", {
        {"en", "Modify single index (1-based)"},
        {"zh", "修改单个索引 (从1开始)"},
    }},
    {"filter_multi_index", {
        {"en", "Modify multiple indices"},
        {"zh", "修改多个指定索引"},
    }},
    {"filter_range", {
        {"en", "Modify index range N to M"},
        {"zh", "修改索引范围 N 到 M"},
    }},
    {"filter_addr_suffix", {
        {"en", "Address suffix match (hex)"},
        {"zh", "地址尾数匹配 (十六进制)"},
    }},
    {"filter_value_contains", {
        {"en", "Current value contains string"},
        {"zh", "当前值包含指定字符串"},
    }},
    {"filter_offset", {
        {"en", "Write address offset (supports hex)"},
        {"zh", "写入地址偏移 (支持十六进制)"},
    }},
    {"filter_ex_single", {
        {"en", "'3' modify 3rd"},
        {"zh", "'3' 修改第3个"},
    }},
    {"filter_ex_multi", {
        {"en", "'1,3,5' or '1.3.5'"},
        {"zh", "'1,3,5' 或 '1.3.5'"},
    }},
    {"filter_ex_range", {
        {"en", "'1=10' modify 1st to 10th"},
        {"zh", "'1=10' 修改第1到10个"},
    }},
    {"filter_ex_suffix", {
        {"en", "'@ABC' addr ends with ABC"},
        {"zh", "'@ABC' 地址以ABC结尾"},
    }},
    {"filter_ex_contains", {
        {"en", "'||100' value contains 100"},
        {"zh", "'||100' 值包含100"},
    }},
    {"filter_ex_offset", {
        {"en", "'//+4' addr+4, '//-0x10' addr-16"},
        {"zh", "'//+4' 地址+4, '//-0x10' 地址-16"},
    }},

    {"section_12", {
        {"en", "12. Pointer Chain"},
        {"zh", "12. 指针链 (Pointer Chain)"},
    }},
    {"desc_pointer", {
        {"en", "Resolve multi-level pointer chains to read/write values at dynamic addresses. Supports module-based and virtual base addresses."},
        {"zh", "解析多级指针链，在动态地址上读写数值。支持基于模块和虚拟基址。"},
    }},
    {"card_pointer_title", {
        {"en", "Pointer Read/Write/Lock"},
        {"zh", "指针读写与锁定"},
    }},

    {"rva_jb_warning", {
        {"en", "<b>This feature is only available on jailbroken devices.</b> "},
        {"zh", "<b>此功能仅在越狱环境下可用。</b>"},
    }},
    {"rva_jb_tag", {
        {"en", "Jailbreak Only"},
        {"zh", "仅限越狱"},
    }},
    {"section_13", {
        {"en", "13. RVA Patch"},
        {"zh", "13. RVA 补丁"},
    }},
    {"desc_rva", {
        {"en", "Patch executable memory at module+offset using hex bytes. Automatically handles memory protection (RW→RX). Supports read, write, and restore."},
        {"zh", "在模块+偏移处用十六进制字节修补可执行内存。自动处理内存保护 (RW→RX)。支持读取、写入和恢复。"},
    }},
    {"card_rva_title", {
        {"en", "RVA Read/Patch/Restore"},
        {"zh", "RVA 读取/补丁/恢复"},
    }},

    {"param_pointer_module", {
        {"en", "Module name (e.g. 'UnityFramework')"},
        {"zh", "模块名称 (如 'UnityFramework')"},
    }},
    {"param_pointer_base", {
        {"en", "Base offset from module start (hex string)"},
        {"zh", "模块起始偏移 (十六进制字符串)"},
    }},
    {"param_pointer_offsets", {
        {"en", "Array of offsets for each pointer level"},
        {"zh", "每级指针的偏移数组"},
    }},

    {"param_rva_module", {
        {"en", "Target module name"},
        {"zh", "目标模块名称"},
    }},
    {"param_rva_offset", {
        {"en", "Offset from module base (hex string)"},
        {"zh", "模块基址偏移 (十六进制字符串)"},
    }},
    {"param_rva_hex", {
        {"en", "Hex bytes to write (e.g. 'E0031F2A')"},
        {"zh", "要写入的十六进制字节 (如 'E0031F2A')"},
    }},

    {"section_between", {
        {"en", "7. Range Search (Between)"},
        {"zh", "7. 范围搜索 (Between)"},
    }},
    {"desc_between", {
        {"en", "Search for values within a specified range (min~max). Useful for finding values you know fall within a certain range."},
        {"zh", "搜索指定范围内的数值 (最小值~最大值)。适用于已知数值在某个区间内的场景。"},
    }},
    {"param_between_min", {
        {"en", "Minimum value (string)"},
        {"zh", "最小值 (字符串)"},
    }},
    {"param_between_max", {
        {"en", "Maximum value (string)"},
        {"zh", "最大值 (字符串)"},
    }},

    {"comment_lock_offset", {
        {"en", "// Lock with address offset (use 0x prefix for hex, e.g. //+0x8)"},
        {"zh", "// 带地址偏移锁定 (十六进制加0x前缀, 如 //+0x8)"},
    }},
};

#endif /* VMScriptGuideStrings_h */
