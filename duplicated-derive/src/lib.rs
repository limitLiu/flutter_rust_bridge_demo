use proc_macro::TokenStream;
use syn::{parse_macro_input, DeriveInput};

#[proc_macro_derive(Duplicated)]
pub fn derive_duplicated(i: TokenStream) -> TokenStream {
  fn generate(syntax_tree: DeriveInput) -> syn::Result<proc_macro2::TokenStream> {
    let struct_name = syntax_tree.ident;

    Ok(quote::quote! {
      impl #struct_name {
          pub fn from(json: String) -> Result<#struct_name> {
              Ok(sonic_rs::from_str::<#struct_name>(&json)?)
          }
      }
    })
  }
  let syntax_tree = parse_macro_input!(i as DeriveInput);
  match generate(syntax_tree) {
    Ok(st) => st.into(),
    Err(e) => e.to_compile_error().into(),
  }
}
