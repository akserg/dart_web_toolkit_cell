//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell;

/**
 * A superclass for {@link Cell}s that render or escape a String argument as
 * HTML.
 *
 * @param <C> the type that this Cell represents
 */
abstract class AbstractSafeHtmlCell<C> extends AbstractCell<C> {

  final util.SafeHtmlRenderer<C> _renderer;

  /**
   * Construct an AbstractSafeHtmlCell using a given {@link SafeHtmlRenderer}
   * that will consume a given set of events.
   * 
   * @param _renderer a SafeHtmlRenderer
   * @param consumedEvents a Set of event names
   */
  AbstractSafeHtmlCell(this._renderer, [List<String> consumedEvents = null]) : super(consumedEvents);

  /**
   * Return the {@link SafeHtmlRenderer} used by this cell.
   *
   * @return a {@link SafeHtmlRenderer} instance
   */
  util.SafeHtmlRenderer<C> getRenderer() {
    return _renderer;
  }

  void render(CellContext context, C data, util.SafeHtmlBuilder sb) {
    if (data == null) {
      renderSafeHtml(context, null, sb);
    } else {
      renderSafeHtml(context, _renderer.renderAsSafeHtml(data), sb);
    }
  }

  /**
   * Render the cell contents after they have been converted to {@link SafeHtml}
   * form.
   * 
   * @param context the original context to render
   * @param data a {@link SafeHtml} string
   * @param sb the {@link SafeHtmlBuilder} to be written to
   */
  void renderSafeHtml(CellContext context, util.SafeHtml data, util.SafeHtmlBuilder sb);
}
