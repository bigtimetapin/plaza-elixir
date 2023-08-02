const mp = new MercadoPago("APP_USR-7fa93b75-08c8-44b3-9e23-58cf238f1080");
const bricksBuilder = mp.bricks();
const _renderCardPaymentBrick = async (bricksBuilder, phxEventPusher) => {
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
          Promise.resolve(console.log(cardFormData)).then(phxEventPusher(cardFormData)).then(resolve())
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
const _renderStatusScreenBrick = async (bricksBuilder, paymentId) => {
  const settings = {
    initialization: {
      paymentId: paymentId, // id do pagamento a ser mostrado
    },
    callbacks: {
      onReady: () => {
        /*
          Callback chamado quando o Brick estiver pronto.
          Aqui você pode ocultar loadings do seu site, por exemplo.
        */
        console.log("ready");
      },
      onError: (error) => {
        // callback chamado para todos os casos de erro do Brick
        console.error(error);
      },
    },
  };
  window.statusScreenBrickController = await bricksBuilder.create(
    'statusScreen',
    'statusScreenBrick_container',
    settings,
  );
};
export function renderStatusScreenBrick(paymentId) {
  _renderStatusScreenBrick(bricksBuilder, paymentId);
}

export function renderCardPaymentBrick(phxEventPusher) {
  _renderCardPaymentBrick(bricksBuilder, phxEventPusher);
}
