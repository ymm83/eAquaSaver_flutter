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

export 'eaquasaver_msg.pbenum.dart';

class eAquaSaverMessage extends $pb.GeneratedMessage {
  factory eAquaSaverMessage({
    $core.int? temperature,
    $core.int? hotTemperature,
    $core.int? coldTemperature,
    $core.int? currentRecovered,
    $core.int? currentColdUsed,
    $core.int? currentHotUsed,
    $core.int? totalRecovered,
    $core.int? totalColdUsed,
    $core.int? totalHotUsed,
    $core.int? targetTemperature,
    $core.int? minimalTemperature,
    $core.int? ambientTemperature,
    $core.int? state,
  }) {
    final $result = create();
    if (temperature != null) {
      $result.temperature = temperature;
    }
    if (hotTemperature != null) {
      $result.hotTemperature = hotTemperature;
    }
    if (coldTemperature != null) {
      $result.coldTemperature = coldTemperature;
    }
    if (currentRecovered != null) {
      $result.currentRecovered = currentRecovered;
    }
    if (currentColdUsed != null) {
      $result.currentColdUsed = currentColdUsed;
    }
    if (currentHotUsed != null) {
      $result.currentHotUsed = currentHotUsed;
    }
    if (totalRecovered != null) {
      $result.totalRecovered = totalRecovered;
    }
    if (totalColdUsed != null) {
      $result.totalColdUsed = totalColdUsed;
    }
    if (totalHotUsed != null) {
      $result.totalHotUsed = totalHotUsed;
    }
    if (targetTemperature != null) {
      $result.targetTemperature = targetTemperature;
    }
    if (minimalTemperature != null) {
      $result.minimalTemperature = minimalTemperature;
    }
    if (ambientTemperature != null) {
      $result.ambientTemperature = ambientTemperature;
    }
    if (state != null) {
      $result.state = state;
    }
    return $result;
  }
  eAquaSaverMessage._() : super();
  factory eAquaSaverMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory eAquaSaverMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'eAquaSaverMessage', createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'temperature', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'hotTemperature', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'coldTemperature', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'currentRecovered', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'currentColdUsed', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'currentHotUsed', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'totalRecovered', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'totalColdUsed', $pb.PbFieldType.OU3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'totalHotUsed', $pb.PbFieldType.OU3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'targetTemperature', $pb.PbFieldType.OU3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'minimalTemperature', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'ambientTemperature', $pb.PbFieldType.OU3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  eAquaSaverMessage clone() => eAquaSaverMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  eAquaSaverMessage copyWith(void Function(eAquaSaverMessage) updates) => super.copyWith((message) => updates(message as eAquaSaverMessage)) as eAquaSaverMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static eAquaSaverMessage create() => eAquaSaverMessage._();
  eAquaSaverMessage createEmptyInstance() => create();
  static $pb.PbList<eAquaSaverMessage> createRepeated() => $pb.PbList<eAquaSaverMessage>();
  @$core.pragma('dart2js:noInline')
  static eAquaSaverMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<eAquaSaverMessage>(create);
  static eAquaSaverMessage? _defaultInstance;

  /// Mixtured water temperature in x10 Celsius degrees
  @$pb.TagNumber(1)
  $core.int get temperature => $_getIZ(0);
  @$pb.TagNumber(1)
  set temperature($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTemperature() => $_has(0);
  @$pb.TagNumber(1)
  void clearTemperature() => clearField(1);

  /// Hot Pipe Water Temperature in x10 Celsius degrees
  @$pb.TagNumber(2)
  $core.int get hotTemperature => $_getIZ(1);
  @$pb.TagNumber(2)
  set hotTemperature($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHotTemperature() => $_has(1);
  @$pb.TagNumber(2)
  void clearHotTemperature() => clearField(2);

  /// Cold Pipe WaterTemperature in x10 Celsius degrees
  @$pb.TagNumber(3)
  $core.int get coldTemperature => $_getIZ(2);
  @$pb.TagNumber(3)
  set coldTemperature($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasColdTemperature() => $_has(2);
  @$pb.TagNumber(3)
  void clearColdTemperature() => clearField(3);

  /// Current recovered water in centilitres
  @$pb.TagNumber(4)
  $core.int get currentRecovered => $_getIZ(3);
  @$pb.TagNumber(4)
  set currentRecovered($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCurrentRecovered() => $_has(3);
  @$pb.TagNumber(4)
  void clearCurrentRecovered() => clearField(4);

  /// Current wasted cold water in centilitres
  @$pb.TagNumber(5)
  $core.int get currentColdUsed => $_getIZ(4);
  @$pb.TagNumber(5)
  set currentColdUsed($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasCurrentColdUsed() => $_has(4);
  @$pb.TagNumber(5)
  void clearCurrentColdUsed() => clearField(5);

  /// Current wasted hot water in centilitres
  @$pb.TagNumber(6)
  $core.int get currentHotUsed => $_getIZ(5);
  @$pb.TagNumber(6)
  set currentHotUsed($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasCurrentHotUsed() => $_has(5);
  @$pb.TagNumber(6)
  void clearCurrentHotUsed() => clearField(6);

  /// Total recovered water in centilitres
  @$pb.TagNumber(7)
  $core.int get totalRecovered => $_getIZ(6);
  @$pb.TagNumber(7)
  set totalRecovered($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasTotalRecovered() => $_has(6);
  @$pb.TagNumber(7)
  void clearTotalRecovered() => clearField(7);

  /// Total wasted cold water in centilitres
  @$pb.TagNumber(8)
  $core.int get totalColdUsed => $_getIZ(7);
  @$pb.TagNumber(8)
  set totalColdUsed($core.int v) { $_setUnsignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasTotalColdUsed() => $_has(7);
  @$pb.TagNumber(8)
  void clearTotalColdUsed() => clearField(8);

  /// Total wasted hot water in centilitres
  @$pb.TagNumber(9)
  $core.int get totalHotUsed => $_getIZ(8);
  @$pb.TagNumber(9)
  set totalHotUsed($core.int v) { $_setUnsignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasTotalHotUsed() => $_has(8);
  @$pb.TagNumber(9)
  void clearTotalHotUsed() => clearField(9);

  /// User setted temperature in x10 Celsius degrees
  @$pb.TagNumber(10)
  $core.int get targetTemperature => $_getIZ(9);
  @$pb.TagNumber(10)
  set targetTemperature($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasTargetTemperature() => $_has(9);
  @$pb.TagNumber(10)
  void clearTargetTemperature() => clearField(10);

  /// Minimal temperature, device will not deliver water below this amount, in x10 Celsius degrees
  @$pb.TagNumber(11)
  $core.int get minimalTemperature => $_getIZ(10);
  @$pb.TagNumber(11)
  set minimalTemperature($core.int v) { $_setUnsignedInt32(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasMinimalTemperature() => $_has(10);
  @$pb.TagNumber(11)
  void clearMinimalTemperature() => clearField(11);

  /// Ambient temperature in x10 Celsius degrees
  @$pb.TagNumber(12)
  $core.int get ambientTemperature => $_getIZ(11);
  @$pb.TagNumber(12)
  set ambientTemperature($core.int v) { $_setUnsignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasAmbientTemperature() => $_has(11);
  @$pb.TagNumber(12)
  void clearAmbientTemperature() => clearField(12);

  /// Device current state
  @$pb.TagNumber(13)
  $core.int get state => $_getIZ(12);
  @$pb.TagNumber(13)
  set state($core.int v) { $_setUnsignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasState() => $_has(12);
  @$pb.TagNumber(13)
  void clearState() => clearField(13);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
