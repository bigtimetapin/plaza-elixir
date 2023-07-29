export const mp = new MercadoPago("APP_USR-7fa93b75-08c8-44b3-9e23-58cf238f1080");
const bricksBuilder = mp.bricks();
const renderCardPaymentBrick = async (bricksBuilder) => {
  const settings = {
    initialization: {
      amount: 100, //value of the payment to be processed
    },
    customization: {
      visual: {
        style: {
          theme: 'dark' // 'default' |'dark' | 'bootstrap' | 'flat'
        }
      }
    },
    callbacks: {
      onSubmit: (cardFormData) => {
        // callback called when clicking on the submit data button
        return new Promise((resolve, reject) => {
          Promise.resolve(console.log(cardFormData)).then(resolve())
        });
      },
      onReady: () => {
        // handle form ready
      },
      onError: (error) => {
        // handle error
      }
    }
  }
  cardPaymentBrickController = await bricksBuilder.create('cardPayment', 'cardPaymentBrick_container', settings);
};
renderCardPaymentBrick(bricksBuilder);
