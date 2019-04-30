var conf = {
      name: 'Event Schemas',
      address: './repositories',

      visibilityOptions: {
          size: {
              use: true,
              type: 'readable' //raw, readable, both
          },
          date: {
              use: false,
              type: 'raw' //raw, moment, both
          }
      }
};
