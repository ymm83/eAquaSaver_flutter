//
//  Generated code. Do not modify.
//  source: eaquasaver_msg.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class DeviceState extends $pb.ProtobufEnum {
  static const DeviceState SLEEP = DeviceState._(0, _omitEnumNames ? '' : 'SLEEP');
  static const DeviceState IDLE = DeviceState._(1, _omitEnumNames ? '' : 'IDLE');
  static const DeviceState TEMP_AJUST = DeviceState._(2, _omitEnumNames ? '' : 'TEMP_AJUST');
  static const DeviceState RECOVERING = DeviceState._(3, _omitEnumNames ? '' : 'RECOVERING');

  static const $core.List<DeviceState> values = <DeviceState> [
    SLEEP,
    IDLE,
    TEMP_AJUST,
    RECOVERING,
  ];

  static final $core.Map<$core.int, DeviceState> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DeviceState? valueOf($core.int value) => _byValue[value];

  const DeviceState._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
