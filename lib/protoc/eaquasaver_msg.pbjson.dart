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

@$core.Deprecated('Use deviceStateDescriptor instead')
const DeviceState$json = {
  '1': 'DeviceState',
  '2': [
    {'1': 'SLEEP', '2': 0},
    {'1': 'IDLE', '2': 1},
    {'1': 'TEMP_AJUST', '2': 2},
    {'1': 'RECOVERING', '2': 3},
  ],
};

/// Descriptor for `DeviceState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List deviceStateDescriptor = $convert.base64Decode(
    'CgtEZXZpY2VTdGF0ZRIJCgVTTEVFUBAAEggKBElETEUQARIOCgpURU1QX0FKVVNUEAISDgoKUk'
    'VDT1ZFUklORxAD');

@$core.Deprecated('Use eAquaSaverMessageDescriptor instead')
const eAquaSaverMessage$json = {
  '1': 'eAquaSaverMessage',
  '2': [
    {'1': 'temperature', '3': 1, '4': 1, '5': 12, '8': {}, '10': 'temperature'},
    {'1': 'hot_temperature', '3': 2, '4': 1, '5': 12, '8': {}, '10': 'hotTemperature'},
    {'1': 'cold_temperature', '3': 3, '4': 1, '5': 12, '8': {}, '10': 'coldTemperature'},
    {'1': 'current_recovered', '3': 4, '4': 1, '5': 13, '8': {}, '10': 'currentRecovered'},
    {'1': 'current_cold_used', '3': 5, '4': 1, '5': 13, '8': {}, '10': 'currentColdUsed'},
    {'1': 'current_hot_used', '3': 6, '4': 1, '5': 13, '8': {}, '10': 'currentHotUsed'},
    {'1': 'total_recovered', '3': 7, '4': 1, '5': 13, '10': 'totalRecovered'},
    {'1': 'total_cold_used', '3': 8, '4': 1, '5': 13, '10': 'totalColdUsed'},
    {'1': 'total_hot_used', '3': 9, '4': 1, '5': 13, '10': 'totalHotUsed'},
    {'1': 'target_temperature', '3': 10, '4': 1, '5': 12, '8': {}, '10': 'targetTemperature'},
    {'1': 'minimal_temperature', '3': 11, '4': 1, '5': 12, '8': {}, '10': 'minimalTemperature'},
    {'1': 'ambient_temperature', '3': 12, '4': 1, '5': 12, '8': {}, '10': 'ambientTemperature'},
    {'1': 'state', '3': 13, '4': 1, '5': 12, '8': {}, '10': 'state'},
  ],
};

/// Descriptor for `eAquaSaverMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eAquaSaverMessageDescriptor = $convert.base64Decode(
    'ChFlQXF1YVNhdmVyTWVzc2FnZRIpCgt0ZW1wZXJhdHVyZRgBIAEoDEIHkj8ECAJgAFILdGVtcG'
    'VyYXR1cmUSMAoPaG90X3RlbXBlcmF0dXJlGAIgASgMQgeSPwQIAmAAUg5ob3RUZW1wZXJhdHVy'
    'ZRIyChBjb2xkX3RlbXBlcmF0dXJlGAMgASgMQgeSPwQIAmAAUg9jb2xkVGVtcGVyYXR1cmUSMg'
    'oRY3VycmVudF9yZWNvdmVyZWQYBCABKA1CBZI/AjgQUhBjdXJyZW50UmVjb3ZlcmVkEjEKEWN1'
    'cnJlbnRfY29sZF91c2VkGAUgASgNQgWSPwI4EFIPY3VycmVudENvbGRVc2VkEi8KEGN1cnJlbn'
    'RfaG90X3VzZWQYBiABKA1CBZI/AjgQUg5jdXJyZW50SG90VXNlZBInCg90b3RhbF9yZWNvdmVy'
    'ZWQYByABKA1SDnRvdGFsUmVjb3ZlcmVkEiYKD3RvdGFsX2NvbGRfdXNlZBgIIAEoDVINdG90YW'
    'xDb2xkVXNlZBIkCg50b3RhbF9ob3RfdXNlZBgJIAEoDVIMdG90YWxIb3RVc2VkEjQKEnRhcmdl'
    'dF90ZW1wZXJhdHVyZRgKIAEoDEIFkj8CCAJSEXRhcmdldFRlbXBlcmF0dXJlEjYKE21pbmltYW'
    'xfdGVtcGVyYXR1cmUYCyABKAxCBZI/AggCUhJtaW5pbWFsVGVtcGVyYXR1cmUSNgoTYW1iaWVu'
    'dF90ZW1wZXJhdHVyZRgMIAEoDEIFkj8CCAJSEmFtYmllbnRUZW1wZXJhdHVyZRIbCgVzdGF0ZR'
    'gNIAEoDEIFkj8CCAFSBXN0YXRl');

