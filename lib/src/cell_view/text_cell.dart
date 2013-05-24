//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_view;

/**
 * A {@link Cell} used to render text.
 */
class TextCell extends AbstractSafeHtmlCell<String> {


  /**
   * Constructs a TextCell that uses the provided {@link SafeHtmlRenderer} to
   * render its text.
   * 
   * @param renderer a {@link SafeHtmlRenderer SafeHtmlRenderer<String>} instance
   */
  TextCell([util.SafeHtmlRenderer<String> renderer = null]) : super(renderer == null ? new SimpleSafeHtmlRenderer.getInstance() : renderer);

  /**
   * Render the cell contents after they have been converted to {@link SafeHtml}
   * form.
   * 
   * @param context the original context to render
   * @param data a {@link SafeHtml} string
   * @param sb the {@link SafeHtmlBuilder} to be written to
   */
  void renderSafeHtml(CellContext context, util.SafeHtml value, util.SafeHtmlBuilder sb) {
    if (value != null) {
      sb.append(value);
    }
  }
}
