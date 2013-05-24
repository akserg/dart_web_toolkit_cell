//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * Implemented by widgets that have a
 * {@link HasKeyboardPagingPolicy.KeyboardPagingPolicy}.
 */
abstract class HasKeyboardPagingPolicy extends HasKeyboardSelectionPolicy {

  /**
   * Get the {@link KeyboardPagingPolicy}.
   *
   * @return the paging policy
   * @see #setKeyboardPagingPolicy(KeyboardPagingPolicy)
   */
  KeyboardPagingPolicy getKeyboardPagingPolicy();

  /**
   * Set the {@link KeyboardPagingPolicy}.
   *
   * @param policy the paging policy
   * @see #getKeyboardPagingPolicy()
   */
  void setKeyboardPagingPolicy(KeyboardPagingPolicy policy);
}

/**
 * The policy that determines how keyboard paging will work.
 */
class KeyboardPagingPolicy extends util.Enum<bool> {
  
  const KeyboardPagingPolicy(bool type) : super(type);

  /**
   * Users cannot navigate past the current page.
   */
  static const KeyboardPagingPolicy CURRENT_PAGE = const KeyboardPagingPolicy(true);

  /**
   * Users can navigate between pages.
   */
  static const KeyboardPagingPolicy CHANGE_PAGE = const KeyboardPagingPolicy(false);

  /**
   * If the user navigates to the beginning or end of the current range, the
   * range is increased.
   */
  static const KeyboardPagingPolicy INCREASE_RANGE = const KeyboardPagingPolicy(false);
  
  bool isLimitedToRange() {
    return value;
  }
}
