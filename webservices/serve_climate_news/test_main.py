import pytest
import os

@pytest.fixture
def app():
    # Arrange
    os.environ['PROJECT'] = 'mock_project'
    os.environ['SUBSCRIPTION'] = 'mock_sub'
    os.environ['DATASET'] = 'mock_dataset'
    os.environ['TABLE'] = 'mock_table'
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'mock-credentials.json'
    os.environ['GOOGLE_CLOUD_PROJECT'] = 'mock_project'

    import main
    main.app.testing = True
    return main.app.test_client()


def test_health(app):
    # Arrange
    # Act
    r = app.get('/')

    # Assert
    assert r.status_code == 200
    assert 'Climate News ML' in r.data.decode('utf-8')
