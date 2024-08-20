//
//  Generated code. Do not modify.
//  source: eaquasaver_msg.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use eAquaSaverMessageDescriptor instead')
const eAquaSaverMessage$json = {
  '1': 'eAquaSaverMessage',
  '2': [
    {'1': 'temperature', '3': 1, '4': 1, '5': 13, '10': 'temperature'},
    {'1': 'hot_temperature', '3': 2, '4': 1, '5': 13, '10': 'hotTemperature'},
    {'1': 'cold_temperature', '3': 3, '4': 1, '5': 13, '10': 'coldTemperature'},
    {'1': 'current_recovered', '3': 4, '4': 1, '5': 13, '10': 'currentRecovered'},
    {'1': 'current_cold_used', '3': 5, '4': 1, '5': 13, '10': 'currentColdUsed'},
    {'1': 'current_hot_used', '3': 6, '4': 1, '5': 13, '10': 'currentHotUsed'},
    {'1': 'total_recovered', '3': 7, '4': 1, '5': 4, '10': 'totalRecovered'},
    {'1': 'total_cold_used', '3': 8, '4': 1, '5': 4, '10': 'totalColdUsed'},
    {'1': 'total_hot_used', '3': 9, '4': 1, '5': 4, '10': 'totalHotUsed'},
  ],
};

/// Descriptor for `eAquaSaverMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eAquaSaverMessageDescriptor = $convert.base64Decode(
    'ChFlQXF1YVNhdmVyTWVzc2FnZRIgCgt0ZW1wZXJhdHVyZRgBIAEoDVILdGVtcGVyYXR1cmUSJw'
    'oPaG90X3RlbXBlcmF0dXJlGAIgASgNUg5ob3RUZW1wZXJhdHVyZRIpChBjb2xkX3RlbXBlcmF0'
    'dXJlGAMgASgNUg9jb2xkVGVtcGVyYXR1cmUSKwoRY3VycmVudF9yZWNvdmVyZWQYBCABKA1SEG'
    'N1cnJlbnRSZWNvdmVyZWQSKgoRY3VycmVudF9jb2xkX3VzZWQYBSABKA1SD2N1cnJlbnRDb2xk'
    'VXNlZBIoChBjdXJyZW50X2hvdF91c2VkGAYgASgNUg5jdXJyZW50SG90VXNlZBInCg90b3RhbF'
    '9yZWNvdmVyZWQYByABKARSDnRvdGFsUmVjb3ZlcmVkEiYKD3RvdGFsX2NvbGRfdXNlZBgIIAEo'
    'BFINdG90YWxDb2xkVXNlZBIkCg50b3RhbF9ob3RfdXNlZBgJIAEoBFIMdG90YWxIb3RVc2Vk');

