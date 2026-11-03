import { createRoot } from 'react-dom/client'
import { LanguageProvider } from './i18n'
import { Home } from './components/Home'
import './styles.css'

createRoot(document.getElementById('root')).render(
  <LanguageProvider>
    <Home />
  </LanguageProvider>,
)
