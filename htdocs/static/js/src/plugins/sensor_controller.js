define(function(require) {

    var moment = require("moment");
    var CounterDisplay = require("plugins/counterdisplay");
    var JohnGauge = require("plugins/gauge");
    var Rickshaw = require("libs/rickshaw.min");
    var _handlebars = require("libs/handlebars");

    function SensorController($node, templates) {
        this.$node = $node;
        this.url = this.$node.attr('data-url') + '&format=json';
        this.unit = this.$node.attr('data-unit');
        this.sensorid = this.$node.attr('data-sensorid');
        this.sensorname = this.$node.attr('data-sensorname');
        this.dashboardUrl = this.$node.attr('data-dashboard_url') || '';
        this.showGraph = ! _.contains([false, 'False', 'false', 0, '0'], this.$node.data('showGraph'));
        this.thresholds = this.parseThresholds();

        this.displayGauge = true;
        if (this.unit.toLowerCase() === 'percent' || this.unit.substr(0, 1) === '%') {
            this.maxValue = 100;  // Max value for graphs and gauges
            this.sensorsymbol = '%';
        } else if (['celsius', 'degrees'].indexOf(this.unit.toLowerCase()) >= 0) {
            this.maxValue = 50;  // Max value for graphs and gauges
            this.sensorsymbol = '\u00B0';
        } else {
            this.displayGauge = false;
        }

        var $html = this.render(templates.sensorTemplate);
        this.graphNode = $html.find('.rs-graphnode');
        this.graphYnode = $html.find('.rs-ynode');
        this.currentNode = $html.find('.current');
        this.sliderNode = $html.find('.rs-slidernode');

        this.addDashboardListener($html);

        this.detailTemplate = templates.detailsTemplate;
        this.counterTemplate = templates.counterTemplate;

        this.update();
        var self = this;
        setInterval(function () {
            self.update();
        }, 60000);
    }

    SensorController.prototype = {
        render: function (template) {
            var $html = $(template({
                legend: this.sensorname,
                dashboardUrl: this.dashboardUrl,
                sensorid: this.sensorid,
                showGraph: this.showGraph
            }));
            $html.appendTo(this.$node);
            if (this.displayGauge) {
                $html.find('.current').addClass('gauge');
            } else {
                $html.find('.current').addClass('counter');
            }
            return $html;
        },
        addDashboardListener: function ($html) {
            var self = this;
            $html.find('.add-to-dashboard').one('click', function(event) {
                var $element = $(this);
                event.preventDefault();
                var request = $.post(this.dataset.url);
                request.done(function() {
                    $element.removeClass('secondary').addClass('success');
                });
                request.fail(function() {
                    $element.removeClass('secondary').addClass('failure');
                });
            });
        },
        parseThresholds: function () {
            var input = this.$node.attr('data-thresholds');
            if (input) {
                /* TOOD: Actually care about the bigger than, smaller than issue */
                var values = input.split(',');
                for (var i = 0, j = values.length; i < j; i++) {
                    values[i] = parseFloat(values[i].replace(/\D/g, ''));
                }
                return values;
            } else {
                return null;
            }
        },
        update: function () {
            this.loadData();
        },
        loadData: function () {
            var self = this;
            var minimumValue = 0;
            $.getJSON(this.url, function (data) {
                if (data && data.length) {
                    var datapoints = data[0].datapoints.map(function (point) {
                        return {
                            x: point[1],
                            y: point[0]
                        };
                    });
                    var last = datapoints[datapoints.length - 1].y || datapoints[datapoints.length - 2].y;
                    if (!self.current) {  // Calculate minimum only if no graph has been made.
                        minimumValue = getMinimumValue(datapoints);
                    }

                    self.updateCurrent(last, minimumValue);
                    if (self.showGraph) {
                        self.updateGraph(datapoints);
                    }
                }
            });
        },
        updateCurrent: function (value, minimum) {
            if (!this.current) {
                this.current = this.createCurrent(value, minimum);
            }
            this.current.refresh(value);
        },
        createCurrent: function (value, minimum) {
            if (this.displayGauge) {
                return new JohnGauge({
                    node: this.currentNode.get(0),
                    min: minimum < 0 ? -25 : 0,
                    value: value,
                    max: this.maxValue,
                    thresholds: this.thresholds,
                    unit: this.unit,
                    symbol: this.sensorsymbol,
                    radius: 110
                });
            } else {
                return new CounterDisplay(this.counterTemplate, this.currentNode.prop('id'), 9999, this.unit);
            }
        },
        updateGraph: function (values) {
            if (!this.graph) {
                this.graph = this.createGraph();
            }
            this.graph.series[0].data = values;
            this.graph.render();
        },
        createGraph: function () {
            var graph = new Rickshaw.Graph({
                element: this.graphNode.get(0),
                width: 230,
                height: 100,
                renderer: 'line',
                min: 'auto',
                series: [{
                    color: 'steelblue',
                    data: [{x: 0, y: 0}], // Data is overridden on update
                    name: this.sensorname
                }]
            });
            var slider = new Rickshaw.Graph.RangeSlider({
                graph: graph,
                element: this.sliderNode.get(0)
            });
            // Time formatter for the x-axis
            var unit_formatter = {
                name: '6 hours',
                seconds: 3600 * 6,
                formatter: function (d) {
                    return moment(d).format('HH:mm');
                }
            };
            var x_axis = new Rickshaw.Graph.Axis.Time({
                graph: graph,
                timeUnit: unit_formatter
            });
            var y_axis = new Rickshaw.Graph.Axis.Y({
                graph: graph,
                orientation: 'left',
                element: this.graphYnode.get(0),
                ticks: 4
            });
            // Enables details on hover.
            var self = this;
            var hoverDetail = new Rickshaw.Graph.HoverDetail({
                graph: graph,
                formatter: function (series, x, y) {
                    var date = moment(new Date(x * 1000)).format('DD-MM-YYYY HH:mm');
                    return self.detailTemplate({
                        color: series.color,
                        name: series.name,
                        date: date,
                        number: +y.toFixed(2)
                    });
                }
            });

            return graph;
        }
    };

    /** Get minimum value of an array of datapoints (y=value), skipping NaNs and nulls*/
    function getMinimumValue(datapoints) {
        return Math.min.apply(null, datapoints.map(function (point) {
            return point.y;
        }).filter(function (value) {
            return value !== null && !isNaN(value);
        }));
    }

    return SensorController;

});
