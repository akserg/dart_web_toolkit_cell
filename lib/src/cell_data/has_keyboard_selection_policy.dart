//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * Implemented by widgets that have a
 * {@link HasKeyboardSelectionPolicy.KeyboardSelectionPolicy}.
 */
abstract class HasKeyboardSelectionPolicy {

  /**
   * Get the {@link KeyboardSelectionPolicy}.
   *
   * @return the selection policy
   * @see #setKeyboardSelectionPolicy(KeyboardSelectionPolicy)
   */
  KeyboardSelectionPolicy getKeyboardSelectionPolicy();

  /**
   * Set the {@link KeyboardSelectionPolicy}.
   *
   * @param policy the selection policy
   * @see #getKeyboardSelectionPolicy()
   */
  void setKeyboardSelectionPolicy(KeyboardSelectionPolicy policy);
}

/**
 * The policy that determines how keyboard selection will work.
 */
class KeyboardSelectionPolicy<int> extends util.Enum<int> {
  
  const KeyboardSelectionPolicy(int type) : super (type);

  /**
   * Keyboard selection is disabled.
   */
  static const KeyboardSelectionPolicy DISABLED = const KeyboardSelectionPolicy(0);
  /**
   * Keyboard selection is enabled.
   */
  static const KeyboardSelectionPolicy ENABLED = const KeyboardSelectionPolicy(1);
  /**
   * Keyboard selection is bound to the
   * {@link com.google.gwt.view.client.SelectionModel}.
   */
  static const KeyboardSelectionPolicy BOUND_TO_SELECTION = const KeyboardSelectionPolicy(2);

}