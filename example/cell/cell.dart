import 'dart:html';

import 'dart:html' as dart_html;

import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/data.dart' as data;
import 'package:dart_web_toolkit_cell/cell.dart' as cell;
import 'package:dart_web_toolkit_cell/cell_data.dart' as celldata;
import 'package:dart_web_toolkit_cell/cell_view.dart' as cellview;


//void main_03() {
//  // Create a CellList.
//  cellview.CellList<String> cellList = new cellview.CellList<String>(new cellview.TextCell());
//
//  // Create a list data provider.
//  celldata.ListDataProvider<String> dataProvider = new celldata.ListDataProvider<String>();
//
//  // Add the cellList to the dataProvider.
//  dataProvider.addDataDisplay(cellList as celldata.HasData);
//
//  // Create a form to add values to the data provider.
//  ui.TextBox valueBox = new ui.TextBox();
//  valueBox.text = "Enter new value";
//  ui.Button addButton = new ui.Button("Add value", new event.ClickHandlerAdapter((event.ClickEvent evnt) {
//      // Get the value from the text box.
//      String newValue = valueBox.text;
//
//      // Get the underlying list from data dataProvider.
//      List<String> list = dataProvider.getList();
//
//      // Add the value to the list. The dataProvider will update the cellList.
//      list.add(newValue);
//      
//      dataProvider.flush();
//  }));
//
//  // Add the widgets to the root panel.
//  ui.VerticalPanel vPanel = new ui.VerticalPanel();
//  vPanel.add(valueBox);
//  vPanel.add(addButton);
//  vPanel.add(cellList);
//  ui.RootPanel.get().add(vPanel);
//}


/**
 * The list of data to display.
 */
List<String> DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

//void main() {
//  // Create a cell to render each value.
//  cellview.TextCell textCell = new cellview.TextCell();
//
//  // Create a CellList that uses the cell.
//  cellview.CellList<String> cellList = new cellview.CellList<String>(textCell);
//
//  List<String> values = new List<String>();
//  for (int i = 0; i < 100; i++) {
//    values.add("$i");
//  }
//  
//  // Set the total row count. This isn't strictly necessary, but it affects
//  // paging calculations, so its good habit to keep the row count up to date.
//  cellList.setRowCount(values.length, true);
//
//  cellList.setPageSize(30);
//  
//  // Push the data into the widget.
//  cellList.setRowData(values);
//
//  // Add it to the root panel.
//  ui.RootPanel.get().add(cellList);
//}

void main() {

  // Create a cell to render each value.
  cellview.TextCell textCell = new cellview.TextCell();

  // Create a CellList that uses the cell.
  cellview.CellList<String> cellList = new cellview.CellList<String>(textCell);

  // Set the total row count. This isn't strictly necessary, but it affects
  // paging calculations, so its good habit to keep the row count up to date.
  cellList.setRowCount(DAYS.length, true);

  // Push the data into the widget.
  cellList.setRowData(DAYS);

  // Add it to the root panel.
  ui.RootPanel.get().add(cellList);
}
