//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
library dart_web_toolkit_cell_data;

import "dart:html" as dart_html;
import "dart:math" as math;

import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/util.dart' as util;
import 'package:dart_web_toolkit/data.dart' as data;
import 'package:dart_web_toolkit/scheduler.dart' as scheduler;

import 'cell.dart';

part 'src/cell_data/has_data.dart';
part 'src/cell_data/has_rows.dart';
part 'src/cell_data/range_change_event.dart';
part 'src/cell_data/range.dart';
part 'src/cell_data/selection_model.dart';
part 'src/cell_data/selection_change_event.dart';
part 'src/cell_data/row_count_change_event.dart';
part 'src/cell_data/has_key_provider.dart';
part 'src/cell_data/loading_state_change_event.dart';
part 'src/cell_data/has_data_presenter.dart';
part 'src/cell_data/has_keyboard_paging_policy.dart';
part 'src/cell_data/has_keyboard_selection_policy.dart';
part 'src/cell_data/default_selection_event_manager.dart';
part 'src/cell_data/multi_selection_model.dart';
part 'src/cell_data/set_selection_model.dart';
part 'src/cell_data/list_data_provider.dart';
part 'src/cell_data/abstract_data_provider.dart';

part 'src/cell_data/adapter/selection_change_event_handler_adapter.dart';
part 'src/cell_data/adapter/range_change_event_handler_adapter.dart';