//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell;

/**
 * A cell that renders a button and takes a delegate to perform actions on
 * mouseUp.
 *
 * @param <C> the type that this Cell represents
 */
class ActionCell<C> extends AbstractCell<C> {

  util.SafeHtml _html;
  ActionCellDelegate<C> _delegate;

  /**
   * Construct a new {@link ActionCell}.
   *
   * @param message the message to display on the button
   * @param delegate the delegate that will handle events
   */
  ActionCell(util.SafeHtml message, this._delegate) : 
    super([event.BrowserEvents.CLICK, event.BrowserEvents.KEYDOWN]) {
    this._html = new util.SafeHtmlBuilder().appendHtmlConstant(
        "<button type=\"button\" tabindex=\"-1\">").append(message).appendHtmlConstant(
        "</button>").toSafeHtml();
  }

  /**
   * Construct a new {@link ActionCell} with a text String that does not contain
   * HTML markup.
   *
   * @param text the text to display on the button
   * @param delegate the delegate that will handle events
   */
  ActionCell.fromString(String text, ActionCellDelegate<C> _delegate) : this(util.SafeHtmlUtils.fromString(text), _delegate);

  void onBrowserEvent(CellContext context, dart_html.Element parent, C value,
      dart_html.Event evt, ValueUpdater<C> valueUpdater) {
    super.onBrowserEvent(context, parent, value, evt, valueUpdater);
    if (evt.type == event.BrowserEvents.CLICK) {
      dart_html.EventTarget eventTarget = evt.target;
      if (eventTarget is! dart_html.Element) {
        return;
      }
      //if (parent.getFirstChildElement().isOrHasChild(eventTarget as dart_html.Element)) {
      if (event.Dom.isOrHasChild(parent.$dom_firstElementChild, eventTarget as dart_html.Element)) {
        // Ignore clicks that occur outside of the main element.
        onEnterKeyDown(context, parent, value, evt, valueUpdater);
      }
    }
  }

  void render(CellContext context, C value, util.SafeHtmlBuilder sb) {
    sb.append(_html);
  }

  void onEnterKeyDown(CellContext context, dart_html.Element parent, C value,
      dart_html.Event event, ValueUpdater<C> valueUpdater) {
    _delegate.execute(value);
  }
}

/**
 * The delegate that will handle events from the cell.
 *
 * @param <T> the type that this delegate acts on
 */
abstract class ActionCellDelegate<T> {
  /**
   * Perform the desired action on the given object.
  *
   * @param object the object to be acted upon
   */
  void execute(T object);
}