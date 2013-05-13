//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell;

/**
 * Indicates that a UI component can be collapsed next to another UI component,
 * thus sharing a common border. This allows UI components to appear flush
 * against each other without extra thick borders.
 * 
 * <p>
 * Before collapse:
 * 
 * <pre>
 *   ---------    ----------    ---------
 *  | ButtonA |  |  ButtonB |  | ButtonC |
 *   ---------    ----------    ---------
 * </pre>
 * 
 * <p>
 * After collapse:
 * 
 * <pre>
 *   -----------------------------
 *  | ButtonA | ButtonB | ButtonC |
 *   -----------------------------
 * </pre>
 * 
 * <p>
 * In the above example, ButtonA has right-side collapsed, ButtonB has both left
 * and right-side collapsed, and ButtonC has left-side collapsed.
 */
abstract class IsCollapsible {

  /**
   * Check whether or not the left-side of the UI component is collapsed
   * (sharing border with the component to its left).
   * 
   * @return true if collapsed, false if not
   */
  bool isCollapseLeft();

  /**
   * right Check whether or not the left-side of the UI component is collapsed
   * (sharing border with the component to its left).
   * 
   * @return true if collapsed, false if not
   */
  bool isCollapseRight();

  /**
   * Sets whether the left-side of the UI component is collapsed (sharing border
   * with the component to its left).
   * 
   * @param isCollapsed true if collapsed, false if not
   */
  void setCollapseLeft(bool isCollapsed);

  /**
   * Sets whether the right-side of the UI component is collapsed (sharing
   * border with the component to its right).
   * 
   * @param isCollapsed true if collapsed, false if not
   */
  void setCollapseRight(bool isCollapsed);
}