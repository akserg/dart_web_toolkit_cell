//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell;

/**
 * A simple {@link SafeHtmlRenderer} implementation that calls
 * {@link SafeHtmlUtils#fromString(String)} to escape its arguments.
 */
class SimpleSafeHtmlRenderer implements util.SafeHtmlRenderer<String> {

  static SimpleSafeHtmlRenderer _instance;

  factory SimpleSafeHtmlRenderer.getInstance() {
    if (_instance == null) {
      _instance = new SimpleSafeHtmlRenderer._internal();
    }
    return _instance;
  }
  
  SimpleSafeHtmlRenderer._internal();

  util.SafeHtml renderAsSafeHtml(String object) {
    return (object == null) ? util.SafeHtmlUtils.EMPTY_SAFE_HTML : util.SafeHtmlUtils.fromString(object);
  }

  void render(String object, util.SafeHtmlBuilder appendable) {
    appendable.append(util.SafeHtmlUtils.fromString(object));
  }
}
