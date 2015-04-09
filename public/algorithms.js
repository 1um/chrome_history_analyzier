var redraw;

window.onload = function() {
    var width = $(document).width();
    var height = $(document).height() - 100;
    
    var g = new Graph();
    
    /* modify the edge creation to attach random weights */

    $.getJSON( "/site_graph.json", function( data ) {
      data.nodes.forEach(function(node){
        g.addNode(node);
      });
      data.connections.forEach(function(connection){
        g.addEdge(connection[0], connection[1],{weight:connection[2],label:connection[2]});
      });
      var layouter = new Graph.Layout.Spring(g);
      var renderer = new Graph.Renderer.Raphael('canvas', g, width, height);
    });
    
};