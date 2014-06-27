define([
    'netmap/graph',
    'netmap/models',
    'netmap/collections',
    'libs/jquery',
    'libs/underscore',
    'libs/backbone',
    'libs/backbone-eventbroker',
    'libs/d3.v2'
], function (Graph, Models) {

    var GraphView = Backbone.View.extend({

        el: '#graph-view',

        interests: {
            'netmap:topologyLayerChanged': 'updateTopologyLayer',
            'netmap:netmapViewChanged': 'updateNetmapView',
            'netmap:filterCategoriesChanged': 'updateCategories',
            'netmap:updateGraph': 'update',
            'netmap:saveNodePositions': 'saveNodePositions'
        },

        initialize: function () {

            // TODO: How to define a good starting height
            this.w = this.$el.width();
            this.h = 1200;

            // Initial d3 graph state
            this.force = d3.layout.force()
                .gravity(0.1)
                .charge(-2500)
                .linkDistance(250)
                .size([this.w, this.h])
                ;

            this.nodes = this.force.nodes();
            this.links = this.force.links();
            this.isLoadingForTheFirstTime = true;

            Backbone.EventBroker.register(this);

            this.model = new Graph();
            this.netmapView = this.options.netmapView;

            this.initializeDOM();
            this.bindEvents();
            this.initializeNetmapView();
            this.fetchGraphModel();
        },

        /**
         * Initializes the graph model from the initially selected
         * or default netmapview.
         */
        initializeNetmapView: function () {

            if (this.netmapView === null) { console.log('netmapView === null');
                this.netmapView = new Models.NetmapView();
            }

            this.model.set('viewId', this.netmapView.id);
            this.model.set('layer', this.netmapView.get('topology'));

            var zoomStr = this.netmapView.get('zoom').split(';');
            this.trans = zoomStr[0].split(',');
            this.scale = zoomStr[1];
            this.zoom.translate(this.trans);
            this.zoom.scale(this.scale);

            var selectedCategories = this.netmapView.get('categories');
            _.each(this.model.get('filter_categories'), function (category) {
                category.checked = _.indexOf(selectedCategories, category.name) >= 0;
            });
        },

        /**
         * Initialize the SVG DOM elements
         */
        initializeDOM: function () {

            this.svg = d3.select(this.el)
                .append('svg')
                .attr('width', this.w)
                .attr('height', this.h)
                .attr('viewBox', '0 0 ' + this.w + ' ' + this.h)
                .attr('pointer-events', 'all')
                .attr('overflow', 'hidden')
                ;

            this.boundingBox = this.svg.append('g')
                .attr('id', 'boundingbox');

            // Markers for link cardinality
            var bundleLinkMarkerStart = this.boundingBox.append('marker')
                .attr('id', 'bundlelinkstart')
                .attr('markerWidth', 8)
                .attr('markerHeight', 12)
                .attr('refX', -80)
                .attr('refY', 0)
                .attr('viewBox', '-4 -6 8 12')
                .attr('markerUnits', 'userSpaceOnUse')
                .attr('orient', 'auto');
            bundleLinkMarkerStart.append('rect')
                .attr('x', -3)
                .attr('y', -5)
                .attr('width', 2)
                .attr('height', 10);
            bundleLinkMarkerStart.append('rect')
                .attr('x', 1)
                .attr('y', -5)
                .attr('width', 2)
                .attr('height', 10);
            var bundleLinkMarkerEnd = this.boundingBox.append('marker')
                .attr('id', 'bundlelinkend')
                .attr('markerWidth', 8)
                .attr('markerHeight', 12)
                .attr('refX', 80)
                .attr('refY', 0)
                .attr('viewBox', '-4 -6 8 12')
                .attr('markerUnits', 'userSpaceOnUse')
                .attr('orient', 'auto');
            bundleLinkMarkerEnd.append('rect')
                .attr('x', -3)
                .attr('y', -5)
                .attr('width', 2)
                .attr('height', 10);
            bundleLinkMarkerEnd.append('rect')
                .attr('x', 1)
                .attr('y', -5)
                .attr('width', 2)
                .attr('height', 10);

            // Needed to control the layering of elements
            this.linkGroup = this.boundingBox.append('g').attr('id', 'link-group');
            this.nodeGroup = this.boundingBox.append('g').attr('id', 'node-group');

            this.link = d3.selectAll('.link').data([]);
            this.node = d3.selectAll('.node').data([]);

        },

        /**
         * Bind d3 events
         */
        bindEvents: function() {

            var self = this;

            // Set up zoom listener
            this.zoom = d3.behavior.zoom();
            this.svg.call(this.zoom.on('zoom', function () {
               self.zoomCallback.call(self);
            }));

            // Set up node dragging listener
            this.drag = d3.behavior.drag()
                .on('dragstart', function (node) {
                    self.dragStart.call(this, node, self);
                })
                .on('drag', this.dragMove)
                .on('dragend', this.dragEnd)
                ;

            // Set up resize on window resize
            $(window).resize(function () {
                console.log('graph view resize');
                self.w = self.$el.width();
                self.svg.attr('width', self.w);
            });

            // Set up tick event
            this.force.on('tick', function () {

                self.link.attr('x1', function (o) {
                    return o.source.x;
                }).attr('y1', function (o) {
                    return o.source.y;
                }).attr('x2', function (o) {
                    return o.target.x;
                }).attr('y2', function (o) {
                    return o.target.y;
                });

                self.node.attr('transform', function(o) {
                    return 'translate(' + o.px + "," + o.py + ')';
                });
            });
        },

        /**
         * Gets the nodes and links from the model and filters out
         * those that should not be displayed
         */
        updateNodesAndLinks: function () {

            // Get selected categories
            var categories = _.pluck(_.filter(
                this.model.get('filter_categories'),
                function (category) {
                    return category.checked;
            }), 'name');

            var nodes = this.model.get('nodeCollection').getGraphObjects();
            var vlans = this.model.get('vlanCollection').getGraphObjects();
            var links = this.model.get('linkCollection').getGraphObjects();

            nodes = filterNodesByCategories(nodes, categories);
            links = filterLinksByCategories(links, categories);

            if (!this.netmapView.get('display_orphans')) {
                nodes = removeOrphanNodes(nodes, links);
            }

            this.force.links(links).nodes(nodes);

            this.nodes = this.force.nodes();
            this.links = this.force.links();

            // Set fixed positions
            _.each(this.nodes, function (node) {
                if (node.position) {
                    node.px = node.position.x;
                    node.py = node.position.y;
                    node.fixed = true;
                } else {
                    node.fixed = false;
                }
            });
        },

        update: function () { console.log('graph view update');

            // You wouldn't want this running while updating
            this.force.stop();

            if (this.isLoadingForTheFirstTime) {
                this.isLoadingForTheFirstTime = false;
            }

            this.updateNodesAndLinks();
            this.transformGraph();
            this.render();

            this.force.start();
        },

        render: function () { console.log('graph view render');
            var self = this;

            this.link = this.linkGroup.selectAll('.link')
                .data(this.links, function (link) {
                    return link.source.id + '-' + link.target.id;
                });

            this.link.enter()
                .append('line')
                .attr('class', function (o) {
                    return 'link ' + linkSpeedAsString(findLinkMaxSpeed(o));
                })
                .attr('stroke', function (o) {
                    // TODO: Load based
                    return '#CCCCCC';
                })
                .attr('marker-start', function (o) {
                    if (o.edges.length > 1) {
                        return 'url(#bundlelinkstart)';
                    }
                })
                .attr('marker-end', function (o) {
                    if (o.edges.length > 1) {
                        return 'url(#bundlelinkend)';
                    }
                })
                .attr('opacity', 0)
                    .transition()
                    .duration(750)
                    .attr('opacity', 1)
                ;


            this.link.exit().transition()
                .duration(750)
                .style('opacity', 0)
                .remove()
                ;

            this.node = this.nodeGroup.selectAll('.node')
                .data(this.nodes, function (node) {
                    return node.id;
                });

            var nodeElement = this.node.enter()
                .append('g')
                .attr('class', 'node')
                .on('dblclick', this.dblclick)
                .call(this.drag)
                ;

            nodeElement.append('image')
                .attr('xlink:href', function (o) {
                    return '/static/images/netmap/' + o.category.toLowerCase() + '.png';
                })
                .attr('x', -16)
                .attr('y', -16)
                .attr('width', 32)
                .attr('height', 32)
                ;

            nodeElement.append('text')
                .attr('class', 'sysname')
                .attr('dy', '1.5em')
                .attr('text-anchor', 'middle')
                .text(function (o) {
                    return o.sysname;
                })
                ;

            nodeElement.attr('opacity', 0)
                .transition()
                .duration(750)
                .style('opacity', 1)
                ;

            this.node.exit()
                .transition()
                .duration(750)
                .style('opacity', 0)
                .remove()
                ;
        },

        fetchGraphModel: function () {

            var self = this;

            this.model.fetch({
                success: function () {
                    self.update();
                },
                error: function () { // TODO: Use alert message instead
                    alert('Error loading graph, please try to reload the page');
                }
            });
        },

        updateTopologyLayer: function (layer) { console.log('graph view update topology');

            this.model.set('layer', layer);
            this.fetchGraphModel();
        },

        updateNetmapView: function (view) { console.log('graph view update view');

            var refetchNeeded = this.netmapView.get('topology') !== view.get('topology');

            this.netmapView = view;

            this.model.set('viewId', this.netmapView.id);
            this.model.set('layer', this.netmapView.get('topology'));

            var zoomStr = this.netmapView.get('zoom').split(';');
            this.trans = zoomStr[0].split(',');
            this.scale = zoomStr[1];
            this.zoom.translate(this.trans);
            this.zoom.scale(this.scale);

            var selectedCategories = this.netmapView.get('categories');
            _.each(this.model.get('filter_categories'), function (category) {
                category.checked = _.indexOf(selectedCategories, category.name) >= 0;
            });

            if (refetchNeeded) {
                this.fetchGraphModel();
            } else {
                this.update();
            }
        },

        updateCategories: function (categoryId, checked) { console.log('graph view update filter');

            var categories = this.model.get('filter_categories');
            _.find(categories, function (category) {
                return category.name === categoryId;
            }).checked = checked;

            this.update();
        },

        saveNodePositions: function () {

            var self = this;

            var dirtyNodes = _.map(
                _.filter(this.force.nodes(), function (node) {
                    return node.fixed && node.category && !node.is_elink_node;
                }),
                function (dirtyNode) {
                    return {
                        viewid: self.netmapView.id,
                        netbox: dirtyNode.id,
                        x: dirtyNode.x,
                        y: dirtyNode.y
                    };
                }
            );

            if (dirtyNodes.length) {

                var nodePositions = new Models.NodePositions().set({
                    'data': dirtyNodes,
                    'viewid': this.netmapView.id
                });

                nodePositions.save(nodePositions.get('data'),
                    {
                    success: function () { console.log('nodepositions saved'); },
                    error: function (model, resp, opt) {
                        console.log(resp.responseText);
                    }
                });

            }
        },

        /**
         * Applies the current translation and scale transformations
         * to the graph
         */
        transformGraph: function () {
            this.boundingBox.attr(
                'transform',
                'translate(' + this.trans +
                ') scale(' + this.scale + ')'
            );
        },

        /* d3 callback functions  */

        dragStart: function (node, self) {
            d3.select(this).insert('circle', 'image').attr('r', 20);
            self.force.start(); // d3 crashes without this
        },

        dragMove: function(node) {
            node.px += d3.event.dx;
            node.py += d3.event.dy;
            node.fixed = true;
        },

        dragEnd: function (node) {
            d3.select(this).select('circle').remove();
        },

        zoomCallback: function () {

            this.trans = d3.event.translate;
            this.scale = d3.event.scale;
            this.transformGraph();
            this.netmapView.set('zoom', this.trans.join(',') + ';' + this.scale);
        },

        // TODO do we need this?
        dblclick: function (node) {
        }

    });

    /* Helper functions */

    /**
     * Helper function for filtering a list of nodes by a list of categories.
     * @param nodes
     * @param categories
     */
    function filterNodesByCategories(nodes, categories) {

        return _.filter(nodes, function (node) {
            return _.contains(categories, node.category.toUpperCase());
        });
    }

    /**
     * Helper function for filtering a list of links by a list of categories.
     * @param links
     * @param categories
     */
    function filterLinksByCategories(links, categories) {

        return _.filter(links, function (link) {
            return _.contains(categories, link.source.category.toUpperCase()) &&
                _.contains(categories, link.target.category.toUpperCase());
        });
    }

    /**
     * Helper function for removing any orphaned nodes from the nodes list
     * @param nodes
     * @param links
     * @returns {*}
     */
    function removeOrphanNodes(nodes, links) {

        return _.filter(nodes, function (node) {
            return _.some(links, function (link) {
                return node.id === link.source.id || node.id === link.target.id;
            });
        });
    }


    /**
     * Helper function to find the max speed of a link objects
     * multiple edges, regardless of the layer
     * @param link
     */
    function findLinkMaxSpeed(link) {

        /*
        This is a kind of 'hacky' approach to find out which layer
        the link belongs to. This is needed because the JSON format
        of the object will be different depending on the layer.
         */
        var speed;
        if (Object.prototype.toString.call(link.edges) === "[object Array]") {
            speed = _.max(_.pluck(link.edges, 'link_speed'));
        } else {
            speed = _.max(_.pluck(_.flatten(_.values(link.edges)), 'link_speed'));
        }
        return speed;
    }

    /**
     * Helper function for converting the given speed into
     * the appropriate range class.
     * @param speed
     * @returns {*}
     */
    function linkSpeedAsString(speed) {
        var speedClass;
        if (speed <= 100) {
            speedClass = 'speed0-100';
        }
        else if (speed > 100 && speed <= 512) {
            speedClass = 'speed100-512';
        }
        else if (speed > 512 && speed <= 2048) {
            speedClass = 'speed512-2048';
        }
        else if (speed > 2048 && speed <= 4096) {
            speedClass = 'speed2048-4096';
        }
        else if (speed > 4096) {
            speedClass = 'speed4096';
        }
        else {
            speedClass = 'speedunknown';
        }
        return speedClass;
    }

    return GraphView;
});