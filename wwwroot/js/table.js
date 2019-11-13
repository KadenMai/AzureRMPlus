/**
 * Created by Kaden on 5/2/18.
 */

function format(d) {
  // `d` is the original data object for the row
  return (
    '<table cellpadding="5" cellspacing="0" border="0" style="padding-left:50px;">' +
    "<tr>" +
    "<td>ResourceId:</td>" +
    "<td><a target=_blank href = 'https://portal.azure.com/#@hrblock.onmicrosoft.com/resource" +
    d.ResourceId +
    "'>" +
    d.ResourceId +
    "</a></td>" +
    "</tr>" +
    "<tr>" +
    "<td>Resource Group</td>" +
    "<td>" +
    d.ResourceGroupName +
    "</td>" +
    "</tr>" +
    "<tr>" +
    "<td>Metric</td>" +
    "<td>" +
    d.Metric +
    "</td>" +
    "</tr>" +
    "<tr>" +
    "<td>ExtraInfo</td>" +
    "<td>" +
    d.ExtraInfo +
    "</td>" +
    "</tr>" +

    "<tr>" +
    "<td>List Logs</td>" +
    "<td>" +    
    d.ListLogs.join("<br />") +
    "</td>" +
    "</tr>"
  );
  ("</table>");
}

function getParameterByName(name, url) {
  if (!url) url = window.location.href;
  name = name.replace(/[\[\]]/g, "\\$&");
  var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
    results = regex.exec(url);
  if (!results) return null;
  if (!results[2]) return "";
  return decodeURIComponent(results[2].replace(/\+/g, " "));
}

$(document).ready(function () {
    var Subs = getParameterByName("subs");
    var SubsName = getParameterByName("name");
    'use strict';

    var table = $("#example").DataTable({
        AutoWidth: false,
        lengthMenu: [[100, -1], [100, "All"]],
        ajax: "/API/SubsDetails?subs=" + Subs,
    columns: [
      {
        className: "details-control",
        orderable: false,
        data: null,
        defaultContent: ""
      },
      { data: "ResourceName" },
      { data: "ResourceType" },
      //   { data: "ResourceGroupName" },
        {
            data: "FirstTime",
            //type:  "date-de"
            //render: function (data, type, row) {
            //    var split = data.split(' ');
            //    return 
            //         split[0]
            //},
        },
      { data: "FirstCallerName" },
      { data: "LastTime" },
      { data: "LastCallerName" },
      // { data: "ExtraInfo" },
      // { data: "Metric" },
      { data: "Location" }
    ],
    order: [[5, "desc"]],
    dom: '<"toolbar">frtip',

    fnInitComplete: function() {
        $("div.toolbar").html("<p class='subs'>Name: " + SubsName + "</p>");
    }
  });

  yadcf.init(table, [
    { column_number: 0, filter_type: "none" },
    {
      column_number: 1,
      text_data_delimiter: ",",
      filter_type: "auto_complete"
    },
    {
      column_number: 2,
      text_data_delimiter: ",",
      filter_type: "auto_complete"
    },
    {
      column_number: 3,
        filter_type: "none"
    },
    {
      column_number: 4,
      filter_type: "select"
    },
    {
      column_number: 5,
        filter_type: "none"
    },
    {
      column_number: 6
    },
    {
      column_number: 7
    }
  ]);

  $("a.toggle-vis").on("click", function(e) {
    e.preventDefault();

    // Get the column API object
    var column = table.column($(this).attr("data-column"));

    // Toggle the visibility
    column.visible(!column.visible());
  });

  // Add event listener for opening and closing details
  $("#example tbody").on("click", "td.details-control", function() {
    var tr = $(this).closest("tr");
    var row = table.row(tr);

    if (row.child.isShown()) {
      // This row is already open - close it
      row.child.hide();
      tr.removeClass("shown");
    } else {
      // Open this row
      row.child(format(row.data())).show();
      tr.addClass("shown");
    }
  });
});
