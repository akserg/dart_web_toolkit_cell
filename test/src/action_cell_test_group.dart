//Copyright (C) 2012 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

part of dart_web_toolkit_test;

/**
 * ActionCell Tests.
 */
class ActionCellTestGroup extends TestGroup {

  registerTests() {
    this.testGroupName = "Cell";

    // Static methods
    this.testList["instance"] = instanceTest;
    this.testList["instanceFromString"] = instanceFromStringTest;
    this.testList["render"] = renderTest;
  }

  //***************
  // Static methods
  //***************
  
  /**
   * Create instance of [cell.ActionCell].
   */
  void instanceTest() {
    String message = "Hi";
    cell.ActionCell ac = new cell.ActionCell(util.SafeHtmlUtils.fromString(message), null);
    expect(ac.getConsumedEvents().contains(event.BrowserEvents.CLICK), isTrue);
    expect(ac.getConsumedEvents().contains(event.BrowserEvents.KEYDOWN), isTrue);
  }
  
  /**
   * Create instance of [cell.ActionCell] from string.
   */
  void instanceFromStringTest() {
    String message = "Hi";
    cell.ActionCell ac = new cell.ActionCell.fromString(message, null);
    expect(ac.getConsumedEvents().contains(event.BrowserEvents.CLICK), isTrue);
    expect(ac.getConsumedEvents().contains(event.BrowserEvents.KEYDOWN), isTrue);
  }
  
  /**
   * Render the content.
   */
  void renderTest() {
    String message = "Hi";
    cell.ActionCell ac = new cell.ActionCell.fromString(message, null);
    cell.CellContext context = new cell.CellContext(0, 0, "00");
    util.SafeHtmlBuilder sb = new util.SafeHtmlBuilder();
    ac.render(context, "", sb);
    expect(sb.toSafeHtml().asString(), equals("<button type=\"button\" tabindex=\"-1\">Hi</button>"));
  }
}